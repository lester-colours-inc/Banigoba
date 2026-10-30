'use strict';
const assert = require('node:assert/strict');
const { beforeEach, describe, test } = require('node:test');
const { announceShopLinkHandler } = require('../shopLinks');

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
    let max = Infinity;
    const query = {
      doc: (id) => ({ path: `${path}/${id ?? `auto${db.nextId++}`}` }),
      limit: (n) => {
        max = n;
        return query;
      },
      get: async () => {
        const docs = [...db.docs.keys()]
          .filter((key) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes('/'))
          .slice(0, max)
          .map((key) => ({ id: key.split('/').pop() }));
        return { docs, size: docs.length };
      },
    };
    return query;
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

const stamp = { serverTimestamp: () => 'now' };
const quiet = { info() {}, warn() {} };

const link = (extra = {}) => ({
  ownerId: 'shop1',
  shopName: 'Glow Boutique',
  title: 'Winter coats',
  scope: 'all',
  audience: 'followers',
  active: true,
  ...extra,
});

const event = (data) => ({ params: { linkId: 'L1' }, data: { data: () => data } });

const notices = (uid) =>
  [...db.docs.entries()].filter(([key]) => key.startsWith(`users/${uid}/notifications/`)).map(([, v]) => v);

let db;
let run;

beforeEach(() => {
  db = new FakeDb();
  run = announceShopLinkHandler(db, stamp, quiet);
  // zoe and rudo follow the shop; the shop follows rudo back (friends).
  db.set('users/shop1/followers/zoe', {});
  db.set('users/shop1/followers/rudo', {});
  db.set('users/shop1/following/rudo', {});
});

describe('announceShopLinkHandler', () => {
  test('tells every follower about a followers link', async () => {
    const result = await run(event(link()));

    assert.equal(result.told, 2);
    const [note] = notices('zoe');
    assert.equal(note.type, 'shop_link');
    assert.equal(note.title, 'Glow Boutique');
    assert.equal(note.body, 'shared Winter coats. Try them on and buy.');
    assert.deepEqual(note.extraData, { linkId: 'L1', fromName: 'Glow Boutique' });
    assert.equal(note.senderId, 'shop1');
    assert.equal(note.isRead, false);
    assert.equal(note.timestamp, 'now');
  });

  test('a public link also goes to every follower', async () => {
    assert.equal((await run(event(link({ audience: 'public' })))).told, 2);
  });

  test('a friends link goes only to mutual follows', async () => {
    await run(event(link({ audience: 'friends' })));

    assert.equal(notices('rudo').length, 1);
    assert.equal(notices('zoe').length, 0);
  });

  test('a just-the-link share tells nobody', async () => {
    assert.equal((await run(event(link({ audience: 'link' })))).told, 0);
    assert.equal(notices('zoe').length, 0);
  });

  test('a switched-off link tells nobody', async () => {
    assert.equal((await run(event(link({ active: false })))).told, 0);
  });

  test('never tells the shop itself', async () => {
    db.set('users/shop1/followers/shop1', {});

    await run(event(link()));

    assert.equal(notices('shop1').length, 0);
  });
});
