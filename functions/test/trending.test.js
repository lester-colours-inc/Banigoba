'use strict';
const assert = require('node:assert/strict');
const { describe, test } = require('node:test');
const { normalizeCity, pickPerCity, shouldNotify, trendingLooks } = require('../trending');

const NOW = new Date('2026-10-28T16:00:00Z');
const hoursAgo = (h) => new Date(NOW.getTime() - h * 3600 * 1000);

const aff = (postId, sender, h = 1, extra = {}) => ({
  targetType: 'post',
  targetId: postId,
  targetOwnerId: `owner-${postId}`,
  senderId: sender,
  moderationState: 'clear',
  createdAt: hoursAgo(h),
  ...extra,
});

describe('normalizeCity', () => {
  test('matches the app: lower case, trimmed, country dropped', () => {
    assert.equal(normalizeCity('  Harare, Zimbabwe '), 'harare');
    assert.equal(normalizeCity('BULAWAYO'), 'bulawayo');
    assert.equal(normalizeCity(undefined), '');
  });
});

describe('trendingLooks', () => {
  test('a look affirmed by three different people in a day is trending', () => {
    const result = trendingLooks([aff('p1', 'a'), aff('p1', 'b'), aff('p1', 'c')], NOW);

    assert.equal(result.length, 1);
    assert.equal(result[0].postId, 'p1');
    assert.equal(result[0].ownerId, 'owner-p1');
    assert.equal(result[0].people, 3);
    assert.deepEqual([...result[0].senderIds].sort(), ['a', 'b', 'c']);
  });

  test('one person affirming many times counts once', () => {
    const result = trendingLooks(
      [aff('p1', 'a'), aff('p1', 'a', 2, { definitionId: 'x' }), aff('p1', 'b')],
      NOW,
    );

    assert.deepEqual(result, []);
  });

  test('two people are not enough', () => {
    assert.deepEqual(trendingLooks([aff('p1', 'a'), aff('p1', 'b')], NOW), []);
  });

  test('ignores affirmations older than the window', () => {
    const result = trendingLooks([aff('p1', 'a'), aff('p1', 'b'), aff('p1', 'c', 30)], NOW);

    assert.deepEqual(result, []);
  });

  test('ignores held-back affirmations and things that are not looks', () => {
    const result = trendingLooks(
      [
        aff('p1', 'a'),
        aff('p1', 'b'),
        aff('p1', 'c', 1, { moderationState: 'held' }),
        aff('p2', 'a', 1, { targetType: 'comment' }),
        aff('p2', 'b', 1, { targetType: 'comment' }),
        aff('p2', 'c', 1, { targetType: 'comment' }),
      ],
      NOW,
    );

    assert.deepEqual(result, []);
  });

  test('ranks by people, then by the most recent affirmation', () => {
    const result = trendingLooks(
      [
        ...['a', 'b', 'c'].map((s) => aff('three', s, 5)),
        ...['a', 'b', 'c', 'd'].map((s) => aff('four', s, 6)),
        ...['a', 'b', 'c'].map((s) => aff('three-fresh', s, 1)),
      ],
      NOW,
    );

    assert.deepEqual(result.map((r) => r.postId), ['four', 'three-fresh', 'three']);
  });

  test('accepts Firestore-style timestamps', () => {
    const stamp = (h) => ({ toMillis: () => hoursAgo(h).getTime() });
    const result = trendingLooks(
      ['a', 'b', 'c'].map((s) => aff('p1', s, 1, { createdAt: stamp(2) })),
      NOW,
    );

    assert.equal(result.length, 1);
  });
});

describe('pickPerCity', () => {
  const item = (postId, cityKey, people, latestMillis = 1) => ({ postId, cityKey, people, latestMillis });

  test('chooses the best look in each city', () => {
    const picked = pickPerCity([
      item('a', 'harare', 3),
      item('b', 'harare', 5),
      item('c', 'lagos', 4),
    ]);

    assert.equal(picked.get('harare').postId, 'b');
    assert.equal(picked.get('lagos').postId, 'c');
  });

  test('breaks ties with the newest', () => {
    const picked = pickPerCity([item('old', 'harare', 3, 1), item('new', 'harare', 3, 9)]);

    assert.equal(picked.get('harare').postId, 'new');
  });

  test('leaves out authors with no city', () => {
    assert.equal(pickPerCity([item('a', '', 9)]).size, 0);
  });
});

describe('shouldNotify', () => {
  const base = {
    uid: 'me',
    ownerId: 'owner',
    senderIds: new Set(['x']),
    postId: 'p1',
    today: '2026-10-28',
    user: { cityKey: 'harare' },
    notice: undefined,
  };

  test('notifies someone in the city who has not seen it', () => {
    assert.equal(shouldNotify(base), true);
  });

  test('never the owner or someone who already affirmed it', () => {
    assert.equal(shouldNotify({ ...base, uid: 'owner' }), false);
    assert.equal(shouldNotify({ ...base, uid: 'x' }), false);
  });

  test('respects the switch in Settings', () => {
    assert.equal(shouldNotify({ ...base, user: { notifyTrending: false } }), false);
    assert.equal(shouldNotify({ ...base, user: { notifyTrending: true } }), true);
  });

  test('at most one a day, and never the same look twice', () => {
    assert.equal(shouldNotify({ ...base, notice: { day: '2026-10-28', postIds: ['other'] } }), false);
    assert.equal(shouldNotify({ ...base, notice: { day: '2026-10-27', postIds: ['p1'] } }), false);
    assert.equal(shouldNotify({ ...base, notice: { day: '2026-10-27', postIds: ['other'] } }), true);
  });
});
