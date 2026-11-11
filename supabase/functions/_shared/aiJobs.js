// Pure rules for AI image jobs (see run-ai-job): what a job may ask for, the
// order its steps can run in, and how Gemini's answers are read. No I/O here,
// so it is tested with node (see test/aiJobs.test.js).
//
// A job is a list of image edits ("steps"). Each step sends some pictures and
// an instruction to Gemini and gets back `count` new pictures. A picture is
// either an address or `{ step: n }`: the first picture made by an earlier
// step, which is how a makeover builds hair, then each garment, on top of the
// last result.

export const LIMITS = Object.freeze({
  steps: 8,
  imagesPerStep: 8,
  countPerStep: 2,
  promptChars: 4000,
  labelChars: 80,
  urlChars: 2048,
});

export const KINDS = Object.freeze(['look', 'try_on', 'turn_around', 'makeover']);
export const DOMAINS = Object.freeze(['hair', 'clothing']);

const isObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);

/**
 * True for an https address on a public host. Blocks the obvious ways of
 * pointing the server at itself or a private network.
 */
export function isAllowedImageUrl(raw) {
  if (typeof raw !== 'string' || !raw || raw.length > LIMITS.urlChars) return false;
  let url;
  try {
    url = new URL(raw);
  } catch {
    return false;
  }
  if (url.protocol !== 'https:' || url.username || url.password) return false;
  if (url.port && url.port !== '443') return false;
  const host = url.hostname.toLowerCase();
  if (!host.includes('.') || host.endsWith('.local') || host.endsWith('.internal')) return false;
  if (host.startsWith('[')) return false; // IPv6 literals
  const ipv4 = host.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (ipv4) {
    const [a, b] = [Number(ipv4[1]), Number(ipv4[2])];
    if (a === 10 || a === 127 || a === 0 || a >= 224) return false;
    if (a === 169 && b === 254) return false;
    if (a === 172 && b >= 16 && b <= 31) return false;
    if (a === 192 && b === 168) return false;
    if (a === 100 && b >= 64 && b <= 127) return false;
  }
  return true;
}

/**
 * Checks a job's `input` and returns it cleaned, or throws an Error whose
 * message is safe to store on the job.
 */
export function validateJobInput(kind, input) {
  if (!KINDS.includes(kind)) throw new Error('This kind of job is not supported.');
  if (!isObject(input)) throw new Error('The job is missing its details.');
  const label = typeof input.label === 'string' ? input.label.trim().slice(0, LIMITS.labelChars) : '';
  const rawSteps = input.steps;
  if (!Array.isArray(rawSteps) || rawSteps.length === 0 || rawSteps.length > LIMITS.steps) {
    throw new Error(`A job needs between 1 and ${LIMITS.steps} steps.`);
  }

  const steps = rawSteps.map((step, index) => {
    if (!isObject(step)) throw new Error(`Step ${index + 1} is not valid.`);
    const prompt = typeof step.prompt === 'string' ? step.prompt.trim() : '';
    if (!prompt || prompt.length > LIMITS.promptChars) {
      throw new Error(`Step ${index + 1} needs an instruction.`);
    }
    if (!Array.isArray(step.images) || step.images.length === 0 || step.images.length > LIMITS.imagesPerStep) {
      throw new Error(`Step ${index + 1} needs between 1 and ${LIMITS.imagesPerStep} pictures.`);
    }
    const images = step.images.map((image) => {
      if (typeof image === 'string') {
        if (!isAllowedImageUrl(image)) throw new Error(`Step ${index + 1} has a picture we cannot use.`);
        return image;
      }
      if (isObject(image) && Number.isInteger(image.step) && image.step >= 0 && image.step < index) {
        return { step: image.step };
      }
      throw new Error(`Step ${index + 1} refers to a picture that is not made before it.`);
    });
    const count = step.count === undefined ? 1 : step.count;
    if (!Number.isInteger(count) || count < 1 || count > LIMITS.countPerStep) {
      throw new Error(`Step ${index + 1} asks for too many pictures.`);
    }
    return { prompt, images, count };
  });

  let document = null;
  if (input.document !== undefined && input.document !== null) {
    document = validateDocument(input.document, steps.length);
    if (kind !== 'makeover') throw new Error('Only a makeover keeps a makeover document.');
  }
  return { label, steps, document };
}

/** The makeover document a job reports into, and which steps make each stage. */
function validateDocument(raw, stepCount) {
  if (!isObject(raw) || raw.kind !== 'makeoverJobs') throw new Error('The makeover document is not valid.');
  const id = typeof raw.id === 'string' ? raw.id.trim() : '';
  if (!id || id.length > 100) throw new Error('The makeover document is not valid.');
  if (!Array.isArray(raw.stages) || raw.stages.length === 0) throw new Error('The makeover has no stages.');
  const used = new Set();
  const stages = raw.stages.map((stage) => {
    if (!isObject(stage) || !DOMAINS.includes(stage.domain)) throw new Error('A makeover stage is not valid.');
    if (!Array.isArray(stage.steps) || stage.steps.length === 0) throw new Error('A makeover stage has no steps.');
    for (const step of stage.steps) {
      if (!Number.isInteger(step) || step < 0 || step >= stepCount || used.has(step)) {
        throw new Error('A makeover stage refers to a step that does not exist.');
      }
      used.add(step);
    }
    return { domain: stage.domain, steps: [...stage.steps] };
  });
  return { kind: 'makeoverJobs', id, stages };
}

/** The earlier steps whose pictures [step] needs. */
export function stepDependencies(step) {
  return [...new Set(step.images.filter((image) => typeof image !== 'string').map((image) => image.step))];
}

/**
 * The steps that can start now: not done, not failed, every step they need
 * done. [done] maps a step to its pictures.
 */
export function readySteps(steps, done, started = new Set()) {
  const ready = [];
  steps.forEach((step, index) => {
    if (done[index] || started.has(index)) return;
    if (stepDependencies(step).every((dep) => Array.isArray(done[dep]) && done[dep].length > 0)) {
      ready.push(index);
    }
  });
  return ready;
}

/** The addresses to fetch for [step], with earlier results filled in. */
export function resolveImages(step, done) {
  return step.images.map((image) => (typeof image === 'string' ? image : done[image.step][0]));
}

/** Steps whose results nothing else uses: what the job hands back. */
export function finalSteps(steps) {
  const used = new Set(steps.flatMap(stepDependencies));
  return steps.map((_, index) => index).filter((index) => !used.has(index));
}

/** The first image in a Gemini Interactions API reply. */
export function firstImage(body) {
  const steps = isObject(body) ? body.steps : null;
  if (!Array.isArray(steps)) throw new Error('Gemini response had no steps.');
  for (const step of steps) {
    if (!isObject(step) || !Array.isArray(step.content)) continue;
    for (const block of step.content) {
      if (!isObject(block) || block.type !== 'image') continue;
      if (typeof block.data !== 'string' || !block.data) continue;
      return { data: block.data, mimeType: normalizeMimeType(block.mime_type) };
    }
  }
  const refusal = refusalText(steps);
  throw new RefusalError(refusal ? `The picture could not be made: ${refusal}` : 'Gemini returned no image.');
}

/** A reply the model will give again if asked again, so retrying is pointless. */
export class RefusalError extends Error {}

function refusalText(steps) {
  for (const step of steps) {
    if (!isObject(step) || !Array.isArray(step.content)) continue;
    for (const block of step.content) {
      if (isObject(block) && block.type === 'text' && typeof block.text === 'string' && block.text) {
        return block.text.slice(0, 300);
      }
    }
  }
  return null;
}

export function normalizeMimeType(contentType) {
  if (typeof contentType !== 'string' || !contentType) return 'image/jpeg';
  const mime = contentType.split(';')[0].trim().toLowerCase();
  return mime.startsWith('image/') ? mime : 'image/jpeg';
}

/** True for HTTP statuses worth one more try (rate limits, server trouble). */
export const isRetryableStatus = (status) => status === 429 || status === 408 || status >= 500;

const TITLES = {
  look: 'Your look is ready',
  try_on: 'Your try-on is ready',
  turn_around: 'Every angle is ready',
  makeover: 'Your makeover is ready',
};

/**
 * The person's own photo a job started from: the first address the first
 * step sends. Shown as "before" beside the result.
 */
export function beforeImageOf(input) {
  const first = Array.isArray(input?.steps) ? input.steps[0] : null;
  const images = Array.isArray(first?.images) ? first.images : [];
  const url = images.find((image) => typeof image === 'string' && image);
  return url ?? '';
}

/** The notification (so the push) for a finished job. */
export function notificationFor(job, status, imageUrl) {
  const extra_data = {
    jobId: job.id,
    kind: job.kind,
    status,
    imageUrl: imageUrl ?? '',
    beforeUrl: beforeImageOf(job.input),
  };
  if (status === 'succeeded') {
    return {
      user_id: job.user_id,
      type: 'ai_job',
      title: TITLES[job.kind] ?? 'Your look is ready',
      body: 'Tap to see your before and after.',
      extra_data,
    };
  }
  return {
    user_id: job.user_id,
    type: 'ai_job',
    title: 'Your look did not finish',
    body: 'Something went wrong while making it. Open Banigoba to try again.',
    extra_data,
  };
}

/**
 * The makeover document after the job's progress: each stage's status and
 * pictures, and the finished alternatives (the deepest stage that worked).
 */
export function applyToMakeoverDocument(data, documentSpec, state) {
  const out = { ...(isObject(data) ? data : {}) };
  const stages = { ...(isObject(out.stages) ? out.stages : {}) };
  const now = new Date().toISOString();
  let deepest = null;
  for (const stage of documentSpec.stages) {
    const previous = isObject(stages[stage.domain]) ? stages[stage.domain] : {};
    const last = stage.steps[stage.steps.length - 1];
    const failed = stage.steps.some((step) => state.failed.has(step));
    const succeeded = Array.isArray(state.done[last]) && state.done[last].length > 0;
    const running = !succeeded && !failed && stage.steps.some((step) => state.started.has(step) || state.done[step]);
    let status = 'queued';
    if (succeeded) status = 'succeeded';
    else if (failed) status = 'failed';
    else if (running) status = 'running';
    else if (state.finished) status = 'failed';
    stages[stage.domain] = {
      ...previous,
      status,
      outputImageUrls: succeeded ? state.done[last] : [],
      errorMessage: status === 'failed' ? state.error || 'We could not complete this change.' : '',
      ...(status === 'running' && !previous.startedAt ? { startedAt: now } : {}),
      ...(status === 'succeeded' || status === 'failed' ? { completedAt: previous.completedAt && previous.status === status ? previous.completedAt : now } : {}),
    };
    if (succeeded) deepest = state.done[last];
  }
  out.stages = stages;
  out.alternatives = state.finished && deepest ? [...deepest] : [];
  return out;
}
