'use strict';
const assert = require('node:assert/strict');
const { beforeEach, describe, test } = require('node:test');
const { notifyTrendingJob } = require('../trendingJob');

// A tiny in-memory Firestore: the calls the job makes.
class FakeDb {
  constructor() {
    this.docs = new Map();
    this.nextId = 1;
  }
  set(path, data) {
    this.docs.set(path, data);
  }
  collection(path) {
    const db = this;
    const filters = [];
    let max = Infinity;
    const query = {
      doc: (id) => db.doc(`${path}/${id ?? `auto${db.nextId++}`}`),
      where: (field, op, value) => {
        filters.push([field, op, value]);
        return query;
      },
      limit: (n) => {
        max = n;
        return query;
      },
      get: async () => {
        const matches = (data, [field, op, value]) => {
          const actual = data[field];
          if (op === '==') return actual === value;
          if (op === '>=') return actual !== undefined && new Date(actual) >= new Date(value);
          return false;
        };
        const docs = [...db.docs.entries()]
          .filter(([key]) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes('/'))
          .filter(([, data]) => filters.every((filter) => matches(data, filter)))
          .slice(0, max)
          .map(([key, data]) => ({ id: key.split('/').pop(), exists: true, data: () => data }));
        return { docs, size: docs.length };
      },
    };
    return query;
  }
  doc(path) {
    const db = this;
    return {
      path,
      get: async () => ({ id: path.split('/').pop(), exists: db.docs.has(path), data: () => db.docs.get(path) }),
      collection: (name) => db.collection(`${path}/${name}`),
    };
  }
  batch() {
    const db = this;
    const ops = [];
    return {
      set: (ref, data) => ops.push(() => db.docs.set(ref.path, data)),
      commit: async () => ops.forEach((run) => run()),
    };
  }
}

const NOW = new Date('2026-10-28T16:00:00Z');
const recent = new Date('2026-10-28T10:00:00Z');
const stamp = { serverTimestamp: () => 'now' };
const quiet = { info() {}, warn() {} };

let db;
let run;

const affirm = (id, post, sender, extra = {}) =>
  db.set(`affirmations/${id}`, {
    targetType: 'post',
    targetId: post,
    targetOwnerId: 'tariro',
    senderId: sender,
    moderationState: 'clear',
    createdAt: recent,
    ...extra,
  });

const notifications = (uid) =>
  [...db.docs.entries()].filter(([key]) => key.startsWith(`users/${uid}/notifications/`)).map(([, data]) => data);

beforeEach(() => {
  db = new FakeDb();
  run = notifyTrendingJob(db, stamp, quiet);
  db.set('posts/p1', { authorId: 'tariro', visibility: 'public' });
  db.set('users/tariro', { city: 'Harare', cityKey: 'harare' });
  db.set('users/zoe', { city: 'Harare', cityKey: 'harare' });
  db.set('users/farai', { city: 'Lagos', cityKey: 'lagos' });
  affirm('a1', 'p1', 'rudo');
  affirm('a2', 'p1', 'tino');
  affirm('a3', 'p1', 'nomsa');
});

describe('notifyTrendingJob', () => {
  test('tells people in the city about a trending look, without any count', async () => {
    const result = await run(NOW);

    const [note] = notifications('zoe');
    assert.equal(result.notified, 1);
    assert.equal(note.type, 'trending_look');
    assert.equal(note.title, 'Trending in Harare');
    assert.deepEqual(note.extraData, { postId: 'p1' });
    assert.equal(note.isRead, false);
    assert.doesNotMatch(JSON.stringify(note), /\b3\b/);
  });

  test('does not tell other cities, or the owner', async () => {
    await run(NOW);

    assert.equal(notifications('farai').length, 0);
    assert.equal(notifications('tariro').length, 0);
  });

  test('does not tell someone who already affirmed it', async () => {
    db.set('users/rudo', { city: 'Harare', cityKey: 'harare' });

    await run(NOW);

    assert.equal(notifications('rudo').length, 0);
  });

  test('stays quiet below three people', async () => {
    db.docs.delete('affirmations/a3');

    const result = await run(NOW);

    assert.equal(result.notified, 0);
  });

  test('only public looks trend', async () => {
    db.set('posts/p1', { authorId: 'tariro', visibility: 'friends' });

    assert.equal((await run(NOW)).notified, 0);
  });

  test('respects the switch in Settings', async () => {
    db.set('users/zoe', { city: 'Harare', cityKey: 'harare', notifyTrending: false });

    assert.equal((await run(NOW)).notified, 0);
  });

  test('at most one a day, and not the same look again tomorrow', async () => {
    await run(NOW);
    assert.equal((await run(NOW)).notified, 0);

    const tomorrow = new Date('2026-10-29T16:00:00Z');
    for (const id of ['a1', 'a2', 'a3']) {
      db.docs.set(`affirmations/${id}`, { ...db.docs.get(`affirmations/${id}`), createdAt: new Date('2026-10-29T10:00:00Z') });
    }
    assert.equal((await run(tomorrow)).notified, 0);
  });

  test('picks the best look in the city when several trend', async () => {
    db.set('posts/p2', { authorId: 'tariro', visibility: 'public' });
    for (const [i, sender] of ['rudo', 'tino', 'nomsa', 'kuda'].entries()) affirm(`b${i}`, 'p2', sender);

    await run(NOW);

    const [note] = notifications('zoe');
    assert.deepEqual(note.extraData, { postId: 'p2' });
    assert.equal(notifications('zoe').length, 1);
  });
});

describe('trending by phone location', () => {
  beforeEach(() => {
    db = new FakeDb();
    run = notifyTrendingJob(db, stamp, quiet);
    db.set('posts/p1', { authorId: 'tariro', visibility: 'public' });
    // Tariro and Zoe share an area cell; Farai is in another. None has a typed city.
    db.set('users/tariro', { areaEnabled: true, areaCell: '155:-90' });
    db.set('users/zoe', { areaEnabled: true, areaCell: '155:-90' });
    db.set('users/farai', { areaEnabled: true, areaCell: '143:-101' });
    for (const [i, sender] of ['rudo', 'tino', 'nomsa'].entries()) affirm(`g${i}`, 'p1', sender);
  });

  test('tells people in the same area, who have no typed city', async () => {
    const result = await run(NOW);

    const [note] = notifications('zoe');
    assert.equal(result.notified, 1);
    assert.equal(note.title, 'Trending near you');
    assert.deepEqual(note.extraData, { postId: 'p1' });
  });

  test('does not tell people in another area, or the owner', async () => {
    await run(NOW);

    assert.equal(notifications('farai').length, 0);
    assert.equal(notifications('tariro').length, 0);
  });

  test('a person with both a city and an area is told once a day', async () => {
    db.set('users/tariro', { city: 'Harare', cityKey: 'harare', areaEnabled: true, areaCell: '155:-90' });
    db.set('users/zoe', { city: 'Harare', cityKey: 'harare', areaEnabled: true, areaCell: '155:-90' });

    await run(NOW);

    assert.equal(notifications('zoe').length, 1);
  });

  test('turning location off removes the person from it', async () => {
    db.set('users/zoe', { areaEnabled: false });

    assert.equal((await run(NOW)).notified, 0);
  });
});
