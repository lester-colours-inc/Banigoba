import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import { camelizeRow, flattenRow, productDoc } from '../rows.js';

describe('rows', () => {
  test('camelizeRow renames snake_case columns', () => {
    assert.deepEqual(camelizeRow({ user_id: 'u', image_url: 'x', name: 'n' }), {
      userId: 'u',
      imageUrl: 'x',
      name: 'n',
    });
  });

  test('flattenRow lets columns win over free-form data', () => {
    const flat = flattenRow({ name: 'col', data: { name: 'data', brand: 'b' } });
    assert.equal(flat.name, 'col');
    assert.equal(flat.brand, 'b');
  });

  test('productDoc carries what the matching rules read', () => {
    const doc = productDoc({
      id: 'p1',
      user_id: 's1',
      stock: 3,
      size_inventory: { M: 2 },
      category: 'tops',
      data: { styleTag: 'casual' },
    });
    assert.equal(doc.id, 'p1');
    assert.equal(doc.uploaderId, 's1');
    assert.deepEqual(doc.sizeInventory, { M: 2 });
    assert.equal(doc.styleTag, 'casual');
    assert.equal(doc.stock, 3);
  });
});
