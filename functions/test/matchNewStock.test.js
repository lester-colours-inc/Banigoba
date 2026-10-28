'use strict';
const assert = require('node:assert/strict');
const { beforeEach, describe, test } = require('node:test');
const { matchNewStockHandler, utcDay } = require('../matchNewStock');

// A tiny in-memory Firestore: just the calls the handler makes.
class FakeDb {
  constructor() {
    this.docs = new Map();
  }
  set(path, data) {
    this.docs.set(path, data);
  }
  doc(path) {
    const db = this;
    return {
      path,
      get: async () => snapshot(path, db.docs.get(path)),
      collection: (name) => db.collection(`${path}/${name}`),
    };
  }
  collection(path) {
    const db = this;
    const filters = [];
    let max = Infinity;
    const query = {
      doc: (id) => db.doc(`${path}/${id}`),
      where: (field, op, value) => {
        filters.push([field, value]);
        return query;
      },
      limit: (n) => {
        max = n;
        return query;
      },
      get: async () => {
        const docs = [...db.docs.entries()]
          .filter(([key]) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes('/'))
          .filter(([, data]) => filters.every(([field, value]) => data[field] === value))
          .slice(0, max)
          .map(([key, data]) => snapshot(key, data));
        return { docs, size: docs.length, empty: docs.length === 0 };
      },
    };
    return query;
  }
  batch() {
    const db = this;
    const ops = [];
    return {
      set: (ref, data) => ops.push(() => db.docs.set(ref.path, data)),
      delete: (ref) => ops.push(() => db.docs.delete(ref.path)),
      commit: async () => ops.forEach((run) => run()),
    };
  }
}

function snapshot(path, data) {
  return {
    id: path.split('/').pop(),
    exists: data !== undefined,
    data: () => data,
    get: (field) => (data ? data[field] : undefined),
  };
}

const product = (extra = {}) => ({
  name: 'Blazer',
  category: 'tops',
  uploaderId: 'shop1',
  styleTag: 'corporate',
  stock: 5,
  sizeInventory: { M: 3 },
  ...extra,
});

const event = (after, before) => ({
  params: { productId: 'p1' },
  data: {
    before: { data: () => before },
    after: { data: () => after },
  },
});

const quiet = { info() {}, warn() {} };
const stamp = { serverTimestamp: () => 'now' };

let db;
let run;

beforeEach(() => {
  db = new FakeDb();
  run = matchNewStockHandler(db, stamp, quiet);
  db.set('users/shop1', { displayName: 'Glow' });
  db.set('users/shop1/followers/zoe', {});
  db.set('users/zoe', { stylePreferences: ['Smart'] });
  db.set('users/zoe/private/bodyProfile', { clothingSize: 'M' });
  db.set('user_products/w1', { userId: 'zoe', category: 'tops' });
});

describe('matchNewStockHandler', () => {
  test('writes a card for a follower the new piece suits', async () => {
    await run(event(product()));

    const card = db.docs.get('users/zoe/feedCards/p1');
    assert.equal(card.productId, 'p1');
    assert.equal(card.size, 'M');
    assert.equal(card.score, 5);
    assert.equal(card.day, utcDay());
    assert.deepEqual(card.reasons, ['In your size (M)', 'Suits your Smart style']);
    assert.equal(card.product.name, 'Blazer');
    assert.equal(card.createdAt, 'now');
  });

  test('writes nothing for a piece in nobody\'s size', async () => {
    await run(event(product({ sizeInventory: { XS: 2 } })));

    assert.equal(db.docs.has('users/zoe/feedCards/p1'), false);
  });

  test('does nothing for an ordinary edit', async () => {
    await run(event(product(), product()));

    assert.equal(db.docs.has('users/zoe/feedCards/p1'), false);
  });

  test('cards a restocked piece', async () => {
    await run(event(product(), product({ stock: 0, sizeInventory: { M: 0 } })));

    assert.equal(db.docs.has('users/zoe/feedCards/p1'), true);
  });

  test('respects "not for me"', async () => {
    db.set('users/zoe/feedDismissed/p1', { dismissedAt: 'then' });

    await run(event(product()));

    assert.equal(db.docs.has('users/zoe/feedCards/p1'), false);
  });

  test('keeps to three cards a day, replacing the weakest for a better piece', async () => {
    const today = utcDay();
    for (const [id, score] of [['a', 3], ['b', 5], ['c', 3]]) {
      db.set(`users/zoe/feedCards/${id}`, { score, day: today, createdAt: { toMillis: () => score } });
    }

    await run(event(product()));

    assert.equal(db.docs.has('users/zoe/feedCards/p1'), true);
    assert.equal(db.docs.has('users/zoe/feedCards/a'), false);
    assert.equal(db.docs.has('users/zoe/feedCards/b'), true);
  });

  test('only people who follow the shop get a card', async () => {
    db.set('users/rudo', { stylePreferences: ['Smart'] });
    db.set('users/rudo/private/bodyProfile', { clothingSize: 'M' });

    await run(event(product()));

    assert.equal(db.docs.has('users/rudo/feedCards/p1'), false);
  });

  test('one follower failing does not stop the rest', async () => {
    db.set('users/shop1/followers/bad', {});
    db.set('users/rudo', { stylePreferences: ['Smart'] });
    db.set('users/shop1/followers/rudo', {});
    db.set('users/rudo/private/bodyProfile', { clothingSize: 'M' });
    const original = db.doc.bind(db);
    db.doc = (path) => {
      if (path === 'users/bad') throw new Error('boom');
      return original(path);
    };

    await run(event(product()));

    assert.equal(db.docs.has('users/zoe/feedCards/p1'), true);
    assert.equal(db.docs.has('users/rudo/feedCards/p1'), true);
  });
});

describe('shop insights', () => {
  test('records how many followers a new piece was shown to, for the shop only', async () => {
    await run(event(product()));

    const insight = db.docs.get('product_insights/p1');
    assert.equal(insight.sellerId, 'shop1');
    assert.equal(insight.reach, 1);
    assert.equal(insight.followers, 1);
    assert.equal(insight.updatedAt, 'now');
  });

  test('records zero when no follower suits it', async () => {
    await run(event(product({ sizeInventory: { XS: 2 } })));

    assert.equal(db.docs.get('product_insights/p1').reach, 0);
    assert.equal(db.docs.get('product_insights/p1').followers, 1);
  });

  test('a restock adds to the total', async () => {
    await run(event(product()));
    db.docs.delete('users/zoe/feedCards/p1');
    await run(event(product(), product({ stock: 0, sizeInventory: { M: 0 } })));

    assert.equal(db.docs.get('product_insights/p1').reach, 2);
  });

  test('an ordinary edit records nothing', async () => {
    await run(event(product(), product()));

    assert.equal(db.docs.has('product_insights/p1'), false);
  });

  test('holds no follower names or sizes', async () => {
    await run(event(product()));

    assert.doesNotMatch(JSON.stringify(db.docs.get('product_insights/p1')), /zoe/);
  });
});
