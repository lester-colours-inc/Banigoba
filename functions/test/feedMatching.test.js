'use strict';
const assert = require('node:assert/strict');
const { describe, test } = require('node:test');
const {
  bodyProfileFrom,
  isNewStock,
  matchProduct,
  matchingStyle,
  placeCard,
  sizeFor,
  totalStock,
} = require('../feedMatching');

const body = (extra = {}) => bodyProfileFrom({ clothingSize: 'M', ...extra });

const product = (extra = {}) => ({
  id: 'p1',
  name: 'Shirt',
  category: 'tops',
  uploaderId: 'shop1',
  styleTag: 'corporate',
  stock: 5,
  ...extra,
});

const shopper = (extra = {}) => ({
  userId: 'me',
  body: body(),
  styles: ['Smart'],
  ownedByCategory: { tops: 2 },
  followedSellerIds: new Set(['shop1']),
  ...extra,
});

describe('bodyProfileFrom', () => {
  test('upper-cases the clothing size and drops out-of-range measurements', () => {
    const profile = bodyProfileFrom({
      clothingSize: ' m ',
      measurements: { waist: 80, height: 5, chest: '96' },
    });

    assert.equal(profile.clothingSize, 'M');
    assert.deepEqual(profile.measurements, { waist: 80, chest: 96 });
  });

  test('copes with nothing saved', () => {
    assert.deepEqual(bodyProfileFrom(undefined).measurements, {});
  });
});

describe('sizeFor', () => {
  test('offers the usual size when it is in stock', () => {
    assert.equal(sizeFor(product({ sizeInventory: { M: 2, L: 1 } }), body()), 'M');
  });

  test('is null when the usual size is out and nothing else fits', () => {
    assert.equal(sizeFor(product({ sizeInventory: { M: 0, L: 4 } }), body()), null);
  });

  test('falls to the size the chart says fits when the usual one is tight', () => {
    const tight = product({
      sizeInventory: { M: 2, L: 2 },
      sizeChart: { M: { waist: 78 }, L: { waist: 92 } },
    });

    assert.equal(sizeFor(tight, body({ measurements: { waist: 88 } })), 'L');
  });

  test('keeps the usual size when the chart is silent or comfortable', () => {
    const roomy = product({
      sizeInventory: { M: 2 },
      sizeChart: { M: { waist: 95 } },
    });

    assert.equal(sizeFor(roomy, body({ measurements: { waist: 88 } })), 'M');
  });

  test('a one-size piece passes while in stock', () => {
    assert.equal(sizeFor(product({ stock: 3 }), body()), '');
    assert.equal(sizeFor(product({ stock: 0 }), body()), null);
  });

  test('shoes go by UK shoe size', () => {
    const shoes = product({ category: 'shoes', sizeInventory: { 'UK 6': 1, 'UK 7': 2 } });

    assert.equal(sizeFor(shoes, body({ shoeSize: '7' })), 'UK 7');
    assert.equal(sizeFor(shoes, body({ shoeSize: '9' })), null);
    assert.equal(sizeFor(shoes, body()), null);
  });
});

describe('matchingStyle', () => {
  test('bridges the person\'s styles to the shop tags', () => {
    assert.equal(matchingStyle(product(), ['Smart']), 'Smart');
    assert.equal(matchingStyle(product({ styleTag: 'afrochic' }), ['Traditional']), 'Traditional');
    assert.equal(matchingStyle(product({ styleTag: 'casual' }), ['Smart']), null);
    assert.equal(matchingStyle(product({ styleTag: '' }), ['Smart']), null);
  });
});

describe('matchProduct', () => {
  test('matches a followed shop\'s piece in the person\'s size that suits their style', () => {
    const match = matchProduct(product({ sizeInventory: { M: 2 } }), shopper());

    assert.equal(match.productId, 'p1');
    assert.equal(match.size, 'M');
    assert.equal(match.score, 5);
    assert.deepEqual(match.reasons, ['In your size (M)', 'Suits your Smart style']);
  });

  test('never matches a shop the person does not follow', () => {
    assert.equal(matchProduct(product({ uploaderId: 'stranger' }), shopper()), null);
  });

  test('never matches the person\'s own stock', () => {
    assert.equal(
      matchProduct(product({ uploaderId: 'me' }), shopper({ followedSellerIds: new Set(['me']) })),
      null,
    );
  });

  test('skips a sized piece with nothing in the person\'s size', () => {
    assert.equal(matchProduct(product({ sizeInventory: { XS: 3 } }), shopper()), null);
  });

  test('fills a gap even when the style does not match', () => {
    const match = matchProduct(
      product({ category: 'outerwear', styleTag: 'casual', sizeInventory: { M: 1 } }),
      shopper(),
    );

    assert.equal(match.score, 5);
    assert.ok(match.reasons.includes("Fills a gap: you don't have any outerwear yet"));
  });

  test('needs a style match or a gap', () => {
    assert.equal(matchProduct(product({ styleTag: 'casual', sizeInventory: { M: 1 } }), shopper()), null);
  });

  test('does not call it a gap when the wardrobe is empty', () => {
    assert.equal(
      matchProduct(product({ styleTag: 'casual', sizeInventory: { M: 1 } }), shopper({ ownedByCategory: {} })),
      null,
    );
  });

  test('skips sold-out one-size pieces', () => {
    assert.equal(matchProduct(product({ category: 'accessories', stock: 0 }), shopper()), null);
  });
});

describe('placeCard', () => {
  const card = (id, score, at = 1) => ({ id, score, createdAtMillis: at });

  test('adds while under the daily cap', () => {
    assert.deepEqual(placeCard([card('a', 3)], card('b', 3)), { add: true, remove: [] });
  });

  test('does not add the same piece twice', () => {
    assert.deepEqual(placeCard([card('a', 3)], card('a', 7)), { add: false, remove: [] });
  });

  test('at the cap, a better piece replaces the weakest', () => {
    const today = [card('a', 3, 1), card('b', 5, 2), card('c', 3, 3)];

    assert.deepEqual(placeCard(today, card('d', 7)), { add: true, remove: ['a'] });
  });

  test('at the cap, an equal or weaker piece is left out', () => {
    const today = [card('a', 5), card('b', 5), card('c', 5)];

    assert.deepEqual(placeCard(today, card('d', 5)), { add: false, remove: [] });
  });
});

describe('isNewStock', () => {
  test('is true for a new piece with stock', () => {
    assert.equal(isNewStock(undefined, product()), true);
  });

  test('is false for a new piece with none', () => {
    assert.equal(isNewStock(undefined, product({ stock: 0 })), false);
  });

  test('is true when a sold-out piece is restocked', () => {
    assert.equal(isNewStock(product({ stock: 0 }), product({ stock: 4 })), true);
  });

  test('is false for an ordinary edit or a delete', () => {
    assert.equal(isNewStock(product({ stock: 4 }), product({ stock: 3 })), false);
    assert.equal(isNewStock(product(), undefined), false);
  });
});

test('totalStock sums sizes', () => {
  assert.equal(totalStock(product({ sizeInventory: { S: 1, M: 2 } })), 3);
});
