// Runs one AI image job (a row in `ai_jobs`). Called by the database (pg_net)
// when a job is added and by the minute sweep when one stalls; the app never
// calls it. It answers at once and does the work in the background, so the
// app being closed changes nothing.
//
// Each finished step is written to the job straight away, so a run that dies
// (time limit, deploy) is picked up by the sweep and carries on from there
// rather than paying for the same pictures twice.
import {
  applyToMakeoverDocument,
  finalSteps,
  firstImage,
  isAllowedImageUrl,
  isRetryableStatus,
  normalizeMimeType,
  notificationFor,
  readySteps,
  RefusalError,
  resolveImages,
  validateJobInput,
} from '../_shared/aiJobs.js';
import { isServiceCaller, json, serviceClient } from '../_shared/server.ts';

const GEMINI_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/interactions';
/** Nano Banana 2 (Gemini 3.1 Flash Image), as the app used before. */
const GEMINI_MODEL = Deno.env.get('GEMINI_IMAGE_MODEL') || 'gemini-3.1-flash-image';
/** Pins the response schema so a change upstream cannot reshape `steps`. */
const GEMINI_API_REVISION = '2026-05-20';
const GEMINI_TIMEOUT_MS = 120_000;
const FETCH_TIMEOUT_MS = 30_000;
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const BUCKET = 'user-images';
/**
 * Past this, no new step is started in this run: the job is handed to a fresh
 * run so the platform's wall-clock limit never cuts a paid call short.
 */
const TIME_BUDGET_MS = Number(Deno.env.get('AI_JOB_TIME_BUDGET_MS') ?? '90000');

type ImageRef = string | { step: number };
interface Step {
  prompt: string;
  images: ImageRef[];
  count: number;
}
interface DocumentSpec {
  kind: 'makeoverJobs';
  id: string;
  stages: { domain: string; steps: number[] }[];
}
interface JobInput {
  label: string;
  steps: Step[];
  document: DocumentSpec | null;
}
interface JobRow {
  id: string;
  user_id: string;
  kind: string;
  status: string;
  input: Record<string, unknown>;
  result: { steps?: (string[] | null)[] };
  attempts: number;
}
interface RunState {
  done: (string[] | null)[];
  started: Set<number>;
  failed: Set<number>;
  finished: boolean;
  error: string;
}

declare const EdgeRuntime: { waitUntil(promise: Promise<unknown>): void } | undefined;

Deno.serve(async (req) => {
  if (!isServiceCaller(req)) return json({ error: 'forbidden' }, 403);
  const { jobId } = await req.json().catch(() => ({}));
  if (typeof jobId !== 'string' || !jobId) return json({ error: 'jobId is required' }, 400);

  const work = runJob(jobId).catch((error) => {
    console.error(`run-ai-job ${jobId} crashed`, error);
  });
  if (typeof EdgeRuntime !== 'undefined') {
    EdgeRuntime.waitUntil(work);
    return json({ accepted: true }, 202);
  }
  await work;
  return json({ accepted: true });
});

async function runJob(jobId: string): Promise<void> {
  const db = serviceClient();
  const { data: claimed, error: claimError } = await db.rpc('claim_ai_job', { job: jobId });
  if (claimError) throw claimError;
  const job = claimed as JobRow | null;
  if (!job?.id) return; // Someone else holds it, or it is already finished.

  let input: JobInput;
  try {
    input = validateJobInput(job.kind, job.input) as JobInput;
  } catch (error) {
    await finish(db, job, null, { status: 'failed', error: messageOf(error) });
    return;
  }

  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) {
    await finish(db, job, input, { status: 'failed', error: 'Image generation is not set up yet.' });
    return;
  }

  const previous = Array.isArray(job.result?.steps) ? job.result.steps : [];
  const state: RunState = {
    done: input.steps.map((_, index) => (Array.isArray(previous[index]) ? previous[index] : null)),
    started: new Set(),
    failed: new Set(),
    finished: false,
    error: '',
  };
  const startedAt = Date.now();
  const save = serialize(() => saveProgress(db, job, input, state));

  // Run every step whose pictures exist, in waves; independent steps (the
  // three turn-around angles) run side by side.
  while (true) {
    const wave = readySteps(input.steps, state.done, state.failed);
    if (wave.length === 0 || state.failed.size > 0) break;
    if (Date.now() - startedAt > TIME_BUDGET_MS) {
      await handOff(db, job.id);
      return;
    }
    for (const index of wave) state.started.add(index);
    await save();
    await Promise.all(
      wave.map(async (index) => {
        try {
          state.done[index] = await runStep(input.steps[index], state, job.user_id, apiKey);
        } catch (error) {
          console.error(`run-ai-job ${job.id} step ${index} failed`, error);
          state.failed.add(index);
          state.error ||= error instanceof RefusalError ? messageOf(error) : 'We could not make this picture.';
        } finally {
          state.started.delete(index);
          await save();
        }
      }),
    );
  }

  state.finished = true;
  const complete = state.done.every((urls) => Array.isArray(urls) && urls.length > 0);
  await finish(db, job, input, complete ? { status: 'succeeded' } : { status: 'failed', error: state.error }, state);
}

/** One Gemini call per picture asked for, each stored as soon as it exists. */
async function runStep(step: Step, state: RunState, userId: string, apiKey: string): Promise<string[]> {
  const urls = resolveImages(step, state.done) as string[];
  const images = await Promise.all(urls.map(fetchImage));
  return Promise.all(
    Array.from({ length: step.count }, async () => {
      const image = await withRetry(() => editImage(apiKey, images, step.prompt));
      return upload(userId, image);
    }),
  );
}

/** Shop pictures often sit behind a redirect; every hop is checked. */
const MAX_REDIRECTS = 3;

async function fetchImage(url: string): Promise<{ data: string; mimeType: string }> {
  let current = url;
  let response: Response | null = null;
  for (let hop = 0; hop <= MAX_REDIRECTS; hop += 1) {
    if (!isAllowedImageUrl(current)) throw new Error('A picture address is not allowed.');
    response = await fetch(current, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS), redirect: 'manual' });
    const location = response.headers.get('location');
    if (response.status < 300 || response.status >= 400 || !location) break;
    await response.body?.cancel();
    current = new URL(location, current).toString();
    response = null;
  }
  if (!response) throw new Error('A picture address redirected too many times.');
  if (!response.ok) throw new Error(`Could not download a picture (${response.status}).`);
  const bytes = new Uint8Array(await response.arrayBuffer());
  if (bytes.length > MAX_IMAGE_BYTES) throw new Error('A picture is too large.');
  return { data: toBase64(bytes), mimeType: normalizeMimeType(response.headers.get('content-type')) };
}

async function editImage(
  apiKey: string,
  images: { data: string; mimeType: string }[],
  prompt: string,
): Promise<{ data: string; mimeType: string }> {
  const response = await fetch(GEMINI_ENDPOINT, {
    method: 'POST',
    signal: AbortSignal.timeout(GEMINI_TIMEOUT_MS),
    headers: {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
      'Api-Revision': GEMINI_API_REVISION,
    },
    body: JSON.stringify({
      model: GEMINI_MODEL,
      input: [
        ...images.map((image) => ({ type: 'image', mime_type: image.mimeType, data: image.data })),
        { type: 'text', text: prompt },
      ],
      response_format: { type: 'image', mime_type: 'image/jpeg' },
    }),
  });
  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    throw new GeminiHttpError(response.status, detail.slice(0, 500));
  }
  return firstImage(await response.json());
}

class GeminiHttpError extends Error {
  constructor(readonly status: number, detail: string) {
    super(`Gemini request failed: ${status} ${detail}`);
  }
}

/** One more try for rate limits, timeouts and server errors. */
async function withRetry<T>(call: () => Promise<T>): Promise<T> {
  try {
    return await call();
  } catch (error) {
    const retryable =
      (error instanceof GeminiHttpError && isRetryableStatus(error.status)) ||
      (error instanceof DOMException && error.name === 'TimeoutError');
    if (!retryable) throw error;
    await new Promise((resolve) => setTimeout(resolve, 3000));
    return call();
  }
}

async function upload(userId: string, image: { data: string; mimeType: string }): Promise<string> {
  const db = serviceClient();
  const extension = image.mimeType === 'image/png' ? 'png' : 'jpg';
  const path = `${userId}/tryOnResults/${crypto.randomUUID()}.${extension}`;
  const { error } = await db.storage
    .from(BUCKET)
    .upload(path, fromBase64(image.data), { contentType: image.mimeType, upsert: false });
  if (error) throw error;
  return db.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
}

type Db = ReturnType<typeof serviceClient>;

async function saveProgress(db: Db, job: JobRow, input: JobInput, state: RunState): Promise<void> {
  const { error } = await db
    .from('ai_jobs')
    .update({ result: { steps: state.done }, heartbeat_at: new Date().toISOString() })
    .eq('id', job.id)
    .eq('status', 'running');
  if (error) console.error(`run-ai-job ${job.id} could not save progress`, error);
  if (input.document) await saveDocument(db, job, input.document, state);
}

async function saveDocument(db: Db, job: JobRow, spec: DocumentSpec, state: RunState): Promise<void> {
  const { data: row, error } = await db
    .from('user_documents')
    .select('data')
    .eq('user_id', job.user_id)
    .eq('kind', spec.kind)
    .eq('id', spec.id)
    .maybeSingle();
  if (error || !row) return; // The person deleted it; the job still finishes.
  const data = applyToMakeoverDocument(row.data, spec, state);
  const { error: writeError } = await db
    .from('user_documents')
    .update({ data })
    .eq('user_id', job.user_id)
    .eq('kind', spec.kind)
    .eq('id', spec.id);
  if (writeError) console.error(`run-ai-job ${job.id} could not update the makeover`, writeError);
}

async function finish(
  db: Db,
  job: JobRow,
  input: JobInput | null,
  outcome: { status: 'succeeded' | 'failed'; error?: string },
  state?: RunState,
): Promise<void> {
  const steps = state?.done ?? [];
  const images = input ? (finalSteps(input.steps) as number[]).flatMap((index) => steps[index] ?? []) : [];
  const { data: updated, error } = await db
    .from('ai_jobs')
    .update({
      status: outcome.status,
      error: outcome.error ?? '',
      result: { steps, images },
      heartbeat_at: new Date().toISOString(),
    })
    .eq('id', job.id)
    .eq('status', 'running')
    .select('id');
  if (error) throw error;
  if (!updated?.length) return; // Deleted while running: nobody to tell.

  if (input?.document && state) await saveDocument(db, job, input.document, state);

  const { error: notifyError } = await db
    .from('notifications')
    .insert(notificationFor({ ...job, input: input ?? {} }, outcome.status, images[0]));
  if (notifyError) console.error(`run-ai-job ${job.id} could not notify`, notifyError);
}

/** Puts the job back in the queue for a fresh run, without counting a try. */
async function handOff(db: Db, jobId: string): Promise<void> {
  const { data: row } = await db.from('ai_jobs').select('attempts').eq('id', jobId).single();
  await db
    .from('ai_jobs')
    .update({ status: 'queued', attempts: Math.max(0, (row?.attempts ?? 1) - 1) })
    .eq('id', jobId)
    .eq('status', 'running');
  const base = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!base || !key) return; // The sweep will start it within a minute.
  await fetch(`${base}/functions/v1/run-ai-job`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ jobId }),
  }).catch((error) => console.error(`run-ai-job ${jobId} hand-off failed`, error));
}

/** Makes concurrent calls to [task] run one after another. */
function serialize(task: () => Promise<void>): () => Promise<void> {
  let chain = Promise.resolve();
  return () => {
    chain = chain.then(task, task);
    return chain;
  };
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : 'Something went wrong.';
}

function toBase64(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary);
}

function fromBase64(data: string): Uint8Array {
  const binary = atob(data);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
