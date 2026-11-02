// Turns database rows into the camelCase shapes the matching rules read.
// Columns are snake_case; free-form `data` keys are already camelCase.

const camel = (key) =>
  key.includes('_')
    ? key.split('_').map((part, i) => (i === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1))).join('')
    : key;

/** A row with snake_case columns renamed to camelCase. */
function camelizeRow(row) {
  const out = {};
  for (const [key, value] of Object.entries(row || {})) out[camel(key)] = value;
  return out;
}

/** The free-form `data` keys beside the camelCased columns; columns win. */
function flattenRow(row) {
  const { data, ...columns } = row || {};
  return { ...(data && typeof data === 'object' ? data : {}), ...camelizeRow(columns) };
}

/** A `products` row as the matching rules read a product. */
function productDoc(row) {
  const flat = flattenRow(row);
  return {
    ...flat,
    id: String(row.id),
    uploaderId: row.user_id,
    userId: row.user_id,
    sizeInventory: row.size_inventory || {},
    stock: typeof row.stock === 'number' ? row.stock : Number(row.stock) || 0,
  };
}

export { camelizeRow, flattenRow, productDoc };
