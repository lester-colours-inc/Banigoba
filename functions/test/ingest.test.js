'use strict';
const assert = require('node:assert/strict');
const { beforeEach, describe, test } = require('node:test');
const { MAX_PER_SOURCE, ingestSource, runIngest } = require('../content/ingest');

const NOW = new Date('2026-10-28T12:00:00Z');
const stamp = { serverTimestamp: () => 'now' };
const quiet = { info() {}, warn() {} };

const rssWith = (titles, base = 'https://mag.example') => `<?xml version="1.0"?>
<rss version="2.0"><channel>${titles
  .map(
    (title, i) =>
      `<item><title>${title}</title><link>${base}/${i}</link><pubDate>Tue, 27 Oct 2026 0${i % 9}:00:00 GMT</pubDate></item>`,
  )
  .join('')}</channel></rss>`;

class FakeStore {
  constructor() {
    this.docs = new Map();
  }
  collection(name) {
    const store = this;
    const filters = [];
    let max = Infinity;
    const query = {
      doc: (id) => ({ path: `${name}/${id}` }),
      where: (field, op, value) => {
        filters.push([field, op, value]);
        return query;
      },
      limit: (n) => {
        max = n;
        return query;
      },
      get: async () => {
        const docs = [...store.docs.entries()]
          .filter(([key]) => key.startsWith(`${name}/`))
          .filter(([, data]) => filters.every(([f, op, v]) => op === '<' && data[f] < v))
          .slice(0, max)
          .map(([key, data]) => ({ id: key.split('/').pop(), ref: { path: key }, data: () => data }));
        return { docs, size: docs.length };
      },
    };
    return query;
  }
  batch() {
    const store = this;
    const ops = [];
    return {
      set: (ref, data) => ops.push(() => store.docs.set(ref.path, data)),
      delete: (ref) => ops.push(() => store.docs.delete(ref.path)),
      commit: async () => ops.forEach((run) => run()),
    };
  }
}

const vogue = { id: 'vogue', name: 'Vogue', url: 'https://vogue.example/rss', region: 'intl' };
const herald = { id: 'herald', name: 'The Herald', url: 'https://herald.example/rss', region: 'zw', requireFashion: true };

describe('ingestSource', () => {
  test('returns the stored form of each fashion story', async () => {
    const result = await ingestSource(vogue, {
      fetchText: async () => rssWith(['Spring runway report', 'Harare Fashion Week returns']),
      now: NOW,
    });

    assert.equal(result.error, null);
    assert.equal(result.docs.length, 2);
    assert.deepEqual(result.docs.map((d) => d.kind).sort(), ['event', 'news']);
  });

  test('filters general news feeds to fashion', async () => {
    const result = await ingestSource(herald, {
      fetchText: async () => rssWith(['Parliament passes budget', 'Harare designer shows collection']),
      now: NOW,
    });

    assert.deepEqual(result.docs.map((d) => d.title), ['Harare designer shows collection']);
  });

  test('keeps only the newest stories when a feed is huge', async () => {
    const titles = Array.from({ length: MAX_PER_SOURCE + 20 }, (_, i) => `Fashion story ${i}`);
    const result = await ingestSource(vogue, { fetchText: async () => rssWith(titles), now: NOW });

    assert.equal(result.docs.length, MAX_PER_SOURCE);
  });

  test('reports a fetch failure instead of throwing', async () => {
    const result = await ingestSource(vogue, {
      fetchText: async () => {
        throw new Error('timeout');
      },
      now: NOW,
    });

    assert.deepEqual(result.docs, []);
    assert.equal(result.error, 'timeout');
  });

  test('treats a page that is not a feed as an error', async () => {
    const result = await ingestSource(vogue, {
      fetchText: async () => '<!doctype html><html><body>Just a moment</body></html>',
      now: NOW,
    });

    assert.deepEqual(result.docs, []);
    assert.match(result.error, /no stories/i);
  });
});

describe('runIngest', () => {
  let store;
  beforeEach(() => {
    store = new FakeStore();
  });

  test('stores stories under content_items and records each source', async () => {
    const summary = await runIngest({
      db: store,
      sources: [vogue],
      fetchText: async () => rssWith(['Spring runway report']),
      now: NOW,
      FieldValue: stamp,
      logger: quiet,
    });

    const [path, doc] = [...store.docs.entries()].find(([key]) => key.startsWith('content_items/'));
    assert.match(path, /^content_items\/[0-9a-f]{20}$/);
    assert.equal(doc.title, 'Spring runway report');
    assert.equal(doc.fetchedAt, 'now');
    assert.deepEqual(summary, [{ id: 'vogue', ok: true, count: 1, error: null }]);
    assert.equal(store.docs.get('content_sources/vogue').ok, true);
    assert.equal(store.docs.get('content_sources/vogue').count, 1);
  });

  test('running twice does not duplicate a story', async () => {
    const options = {
      db: store,
      sources: [vogue],
      fetchText: async () => rssWith(['Spring runway report']),
      now: NOW,
      FieldValue: stamp,
      logger: quiet,
    };

    await runIngest(options);
    await runIngest(options);

    assert.equal([...store.docs.keys()].filter((key) => key.startsWith('content_items/')).length, 1);
  });

  test('one source failing does not stop the others', async () => {
    const summary = await runIngest({
      db: store,
      sources: [herald, vogue],
      fetchText: async (url) => {
        if (url.includes('herald')) throw new Error('403');
        return rssWith(['Spring runway report']);
      },
      now: NOW,
      FieldValue: stamp,
      logger: quiet,
    });

    assert.deepEqual(
      summary.map((s) => [s.id, s.ok]),
      [['herald', false], ['vogue', true]],
    );
    assert.equal(store.docs.get('content_sources/herald').error, '403');
  });

  test('removes stories past their expiry', async () => {
    store.docs.set('content_items/old', { title: 'Old', expiresAt: new Date('2026-10-01') });
    store.docs.set('content_items/fresh', { title: 'Fresh', expiresAt: new Date('2026-12-01') });

    await runIngest({
      db: store,
      sources: [],
      fetchText: async () => '',
      now: NOW,
      FieldValue: stamp,
      logger: quiet,
    });

    assert.equal(store.docs.has('content_items/old'), false);
    assert.equal(store.docs.has('content_items/fresh'), true);
  });
});
