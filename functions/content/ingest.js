// Reads each source, stores the fashion stories as credited link previews in
// `content_items`, records how each source did in `content_sources`, and
// removes stories past their expiry. The app only ever reads content_items.
'use strict';

const { parseFeed } = require('./feed');
const { toDoc } = require('./classify');

const MAX_PER_SOURCE = 40;
const CONCURRENCY = 4;
const BATCH = 400;
const FETCH_TIMEOUT_MS = 15000;
const MAX_FEED_BYTES = 3 * 1024 * 1024;
const USER_AGENT = 'BanigobaBot/1.0 (fashion feed reader; links back to the source)';

/** Fetches a feed's text, with a timeout and a size limit. */
async function fetchText(url) {
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

/** The stories from one source: { docs, error }. Never throws. */
async function ingestSource(source, { fetchText: fetcher = fetchText, now = new Date() } = {}) {
  let text;
  try {
    text = await fetcher(source.url);
  } catch (error) {
    return { docs: [], error: error.message || String(error) };
  }
  const parsed = parseFeed(text);
  if (parsed.length === 0) return { docs: [], error: 'no stories in the response' };

  const seen = new Set();
  const docs = [];
  for (const item of parsed) {
    const doc = toDoc(item, source, now);
    if (doc === null || seen.has(doc.id)) continue;
    seen.add(doc.id);
    docs.push(doc);
  }
  docs.sort((a, b) => b.publishedAt - a.publishedAt);
  return { docs: docs.slice(0, MAX_PER_SOURCE), error: null };
}

async function deleteExpired(db, now) {
  const expired = await db.collection('content_items').where('expiresAt', '<', now).limit(BATCH).get();
  if (expired.docs.length === 0) return 0;
  const batch = db.batch();
  for (const doc of expired.docs) batch.delete(doc.ref);
  await batch.commit();
  return expired.docs.length;
}

/**
 * Reads every source and stores the stories. Returns one entry per source:
 * { id, ok, count, error }.
 */
async function runIngest({ db, sources, fetchText: fetcher, now = new Date(), FieldValue, logger = console }) {
  const summary = [];
  for (let i = 0; i < sources.length; i += CONCURRENCY) {
    const group = sources.slice(i, i + CONCURRENCY);
    const results = await Promise.all(group.map((source) => ingestSource(source, { fetchText: fetcher, now })));
    for (let j = 0; j < group.length; j += 1) {
      const source = group[j];
      const { docs, error } = results[j];

      for (let start = 0; start < docs.length; start += BATCH) {
        const batch = db.batch();
        for (const doc of docs.slice(start, start + BATCH)) {
          const { id, ...fields } = doc;
          batch.set(db.collection('content_items').doc(id), {
            ...fields,
            fetchedAt: FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      const entry = { id: source.id, ok: error === null, count: docs.length, error };
      summary.push(entry);
      const sourceBatch = db.batch();
      sourceBatch.set(db.collection('content_sources').doc(source.id), {
        name: source.name,
        url: source.url,
        ok: entry.ok,
        count: entry.count,
        error,
        lastRunAt: FieldValue.serverTimestamp(),
      });
      await sourceBatch.commit();
      if (error !== null) logger.warn(`source ${source.id} failed: ${error}`);
    }
  }
  const removed = await deleteExpired(db, now);
  logger.info(`content ingest: ${summary.filter((s) => s.ok).length}/${sources.length} sources ok, ${removed} expired removed`);
  return summary;
}

module.exports = { MAX_PER_SOURCE, fetchText, ingestSource, runIngest };
