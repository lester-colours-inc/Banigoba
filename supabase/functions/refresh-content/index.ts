// Fashion-content engine (review items E-2, E-3, F-2): every few hours, read
// the publishers' own feeds and store the fashion stories and events as
// credited link previews in `content_items`, which the app reads. Called by
// pg_cron through pg_net.
import { toDoc } from '../_shared/content/classify.js';
import { parseFeed } from '../_shared/content/feed.js';
import { SOURCES } from '../_shared/content/sources.js';
import { isServiceCaller, json, serviceClient } from '../_shared/server.ts';

const MAX_PER_SOURCE = 40;
const CONCURRENCY = 4;
const FETCH_TIMEOUT_MS = 15000;
const MAX_FEED_BYTES = 3 * 1024 * 1024;
const USER_AGENT = 'BanigobaBot/1.0 (fashion feed reader; links back to the source)';

async function fetchText(url: string): Promise<string> {
  const response = await fetch(url, {
    headers: {
      'user-agent': USER_AGENT,
      accept: 'application/rss+xml, application/atom+xml, application/xml, text/xml;q=0.9, */*;q=0.5',
    },
    redirect: 'follow',
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const text = await response.text();
  if (text.length > MAX_FEED_BYTES) throw new Error('feed too large');
  return text;
}

// deno-lint-ignore no-explicit-any
type Doc = Record<string, any>;

async function ingestSource(source: Doc, now: Date): Promise<{ docs: Doc[]; error: string | null }> {
  let text: string;
  try {
    text = await fetchText(source.url);
  } catch (error) {
    return { docs: [], error: error instanceof Error ? error.message : String(error) };
  }
  const parsed = parseFeed(text);
  if (parsed.length === 0) return { docs: [], error: 'no stories in the response' };

  const seen = new Set<string>();
  const docs: Doc[] = [];
  for (const item of parsed) {
    const doc = toDoc(item, source, now);
    if (doc === null || seen.has(doc.id)) continue;
    seen.add(doc.id);
    docs.push(doc);
  }
  docs.sort((a, b) => b.publishedAt - a.publishedAt);
  return { docs: docs.slice(0, MAX_PER_SOURCE), error: null };
}

Deno.serve(async (req) => {
  if (!isServiceCaller(req)) return json({ error: 'forbidden' }, 403);
  const db = serviceClient();
  const now = new Date();
  const summary: Doc[] = [];

  for (let i = 0; i < SOURCES.length; i += CONCURRENCY) {
    const group = SOURCES.slice(i, i + CONCURRENCY);
    const results = await Promise.all(group.map((source: Doc) => ingestSource(source, now)));
    for (let j = 0; j < group.length; j += 1) {
      const source = group[j];
      const { docs, error } = results[j];
      if (docs.length) {
        await db.from('content_items').upsert(
          docs.map((doc) => ({
            id: doc.id,
            title: doc.title,
            url: doc.url,
            image_url: doc.imageUrl,
            source_id: doc.sourceId,
            source_name: doc.sourceName,
            region: doc.region,
            kind: doc.kind,
            places: doc.places,
            topics: doc.topics,
            published_at: doc.publishedAt.toISOString(),
            starts_at: doc.startsAt ? doc.startsAt.toISOString() : null,
            expires_at: doc.expiresAt.toISOString(),
            fetched_at: now.toISOString(),
          })),
        );
      }
      await db.from('content_sources').upsert({
        id: source.id,
        name: source.name,
        url: source.url,
        ok: error === null,
        item_count: docs.length,
        error,
        last_run_at: now.toISOString(),
      });
      summary.push({ id: source.id, ok: error === null, count: docs.length, error });
      if (error !== null) console.warn(`source ${source.id} failed: ${error}`);
    }
  }
  await db.from('content_items').delete().lt('expires_at', now.toISOString());
  console.info(`content ingest: ${summary.filter((s) => s.ok).length}/${SOURCES.length} sources ok`);
  return json({ sources: summary });
});
