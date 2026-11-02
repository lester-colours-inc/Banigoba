// Server copy of the daily-feed matching rules (review items D-4 and A-6).
//
// This is a port of lib/data/models/feed_matching.dart, lib/data/models/
// fit_check.dart and the sizing in lib/data/models/body_profile.dart. Keep the
// two in step: the tests in test/feedMatching.test.js repeat the Dart tests'
// cases. Pure functions with no Firebase imports, so they run anywhere.

const DAILY_CARDS = 3;
const GAP_BELOW = 1;
const SIZED_CATEGORIES = new Set([
  'tops',
  'bottoms',
  'dresses',
  'outerwear',
  'shoes',
]);

// Which shop style tags suit each style a person can choose.
// UNCLEAR: placeholder mapping, same as the app; confirm with the stakeholder.
const STYLE_BRIDGE = {
  casual: ['casual'],
  smart: ['corporate'],
  traditional: ['afrochic', 'traditional'],
  streetwear: ['streetwear'],
  elegant: ['glamour'],
  sporty: ['sporty'],
};

const MEASUREMENT_RANGES = {
  height: [50, 250],
  weight: [20, 300],
  shoulders: [20, 80],
  waist: [40, 200],
  tummy: [40, 220],
  chest: [50, 200],
  hips: [50, 220],
  insideLeg: [40, 110],
};

const CHART_PARTS = ['shoulders', 'chest', 'waist', 'hips', 'insideLeg'];
const ALL_SIZES = '*';

const text = (value) => (value === null || value === undefined ? '' : String(value)).trim();

const asNumber = (value) => {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  const parsed = Number(text(value).replace(',', '.'));
  return text(value) !== '' && Number.isFinite(parsed) ? parsed : null;
};

// ── body profile ────────────────────────────────────────────────────────────

/** The saved profile from users/{uid}/private/bodyProfile, cleaned. */
function bodyProfileFrom(data) {
  const raw = data && typeof data === 'object' ? data : {};
  const measurements = {};
  const stored = raw.measurements && typeof raw.measurements === 'object' ? raw.measurements : {};
  for (const [key, [min, max]] of Object.entries(MEASUREMENT_RANGES)) {
    const value = asNumber(stored[key]);
    if (value !== null && value >= min && value <= max) measurements[key] = value;
  }
  return {
    clothingSize: text(raw.clothingSize).toUpperCase(),
    shoeSize: text(raw.shoeSize),
    measurements,
  };
}

const sizeKey = (label, footwear) => {
  const key = text(label).toUpperCase();
  return footwear ? key.replace(/^UK\s*/, '') : key;
};

/** The label in [available] that matches the person's size, or null. */
function sizeToSelect(body, available, footwear) {
  const wanted = sizeKey(footwear ? body.shoeSize : body.clothingSize, footwear);
  if (wanted === '') return null;
  for (const label of available) {
    if (sizeKey(label, footwear) === wanted) return label;
  }
  return null;
}

// ── stock ───────────────────────────────────────────────────────────────────

const normalizeSize = (value) => text(value).toUpperCase();

/** {"M": 3, "L": 0}, with labels upper-cased and counts as integers. */
function parseSizeInventory(product) {
  const raw = product.sizeInventory;
  if (!raw || typeof raw !== 'object') return {};
  const inventory = {};
  for (const [key, value] of Object.entries(raw)) {
    const size = normalizeSize(key);
    const quantity =
      typeof value === 'number' ? Math.trunc(value) : parseInt(text(value), 10) || 0;
    if (size !== '') inventory[size] = quantity;
  }
  return inventory;
}

/** Everything left: the sum of the sizes, or the single count. */
function totalStock(product) {
  const sizes = parseSizeInventory(product);
  const keys = Object.keys(sizes);
  if (keys.length > 0) return keys.reduce((sum, key) => sum + sizes[key], 0);
  return typeof product.stock === 'number' ? Math.trunc(product.stock) : 0;
}

// ── fit check ───────────────────────────────────────────────────────────────

function verdictFor(part, garment, body) {
  const difference = garment - body;
  if (part === 'shoulders') {
    return difference < -1 ? 'tight' : difference <= 3 ? 'good' : 'loose';
  }
  if (part === 'insideLeg') {
    return difference < -5 ? 'short' : difference <= 3 ? 'good' : 'long';
  }
  return difference < 0 ? 'tight' : difference < 4 ? 'snug' : difference < 14 ? 'good' : 'loose';
}

const penalty = (verdict) =>
  verdict === 'tight' || verdict === 'short'
    ? 3
    : verdict === 'snug' || verdict === 'loose' || verdict === 'long'
      ? 1
      : 0;

const asCm = (value) => {
  if (typeof value === 'number') return value;
  if (value === null || value === undefined) return null;
  const match = String(value).match(/\d+(?:[.,]\d+)?/);
  return match ? Number(match[0].replace(',', '.')) : null;
};

/** {"M": {chest: 100, ...}}, from `sizeChart` or the old shoulder field. */
function sizeChartFrom(product) {
  const sizes = {};
  if (product.sizeChart && typeof product.sizeChart === 'object') {
    for (const [size, measures] of Object.entries(product.sizeChart)) {
      if (!measures || typeof measures !== 'object') continue;
      const parsed = {};
      for (const part of CHART_PARTS) {
        const cm = asCm(measures[part]);
        if (cm !== null && cm > 0) parsed[part] = cm;
      }
      if (Object.keys(parsed).length > 0) sizes[normalizeSize(size)] = parsed;
    }
  }
  if (Object.keys(sizes).length === 0) {
    const shoulders = asCm(product.shoulderMeasurement);
    if (shoulders !== null && shoulders > 0) sizes[ALL_SIZES] = { shoulders };
  }
  return sizes;
}

/** The comparison for [selectedSize]: its parts and whether it is comfortable. */
function fitCheck(chart, body, selectedSize) {
  if (Object.keys(chart).length === 0) return { hasResult: false, isComfortable: true };
  const chosen = normalizeSize(selectedSize);
  const usual = normalizeSize(body.clothingSize);
  const key = chart[chosen]
    ? chosen
    : chart[ALL_SIZES]
      ? ALL_SIZES
      : chart[usual]
        ? usual
        : null;
  if (key === null) return { hasResult: false, isComfortable: true };
  const garment = chart[key];
  const parts = [];
  for (const part of CHART_PARTS) {
    if (garment[part] !== undefined && body.measurements[part] !== undefined) {
      parts.push(verdictFor(part, garment[part], body.measurements[part]));
    }
  }
  return {
    hasResult: parts.length > 0,
    isComfortable: parts.every((verdict) => verdict !== 'tight' && verdict !== 'short'),
  };
}

/** The chart size with the least discomfort, preferring the usual size. */
function recommendSize(chart, body) {
  const usual = normalizeSize(body.clothingSize);
  let best = null;
  let bestScore = Infinity;
  let comparable = false;
  for (const [size, measures] of Object.entries(chart)) {
    if (size === ALL_SIZES) continue;
    let score = 0;
    let count = 0;
    for (const [part, cm] of Object.entries(measures)) {
      if (body.measurements[part] !== undefined) {
        score += penalty(verdictFor(part, cm, body.measurements[part]));
        count += 1;
      }
    }
    if (count === 0) continue;
    comparable = true;
    if (score < bestScore || (score === bestScore && best !== usual && size === usual)) {
      best = size;
      bestScore = score;
    }
  }
  return comparable ? best : null;
}

// ── matching ────────────────────────────────────────────────────────────────

const categoryOf = (product) => text(product.category).toLowerCase();

const sellerOf = (product) =>
  text(product.uploaderId || product.sellerId || product.shopId || product.userId);

/** The style the person chose that this piece suits, or null. */
function matchingStyle(product, styles) {
  const tag = text(product.styleTag || product.style).toLowerCase();
  if (tag === '') return null;
  for (const style of styles) {
    if ((STYLE_BRIDGE[text(style).toLowerCase()] || []).includes(tag)) return style;
  }
  return null;
}

/** The size to offer, or null when none suits. '' means a one-size piece. */
function sizeFor(product, body) {
  const stock = parseSizeInventory(product);
  if (Object.keys(stock).length === 0) {
    const count = typeof product.stock === 'number' ? product.stock : 1;
    return count > 0 ? '' : null;
  }
  const inStock = Object.keys(stock).filter((size) => stock[size] > 0);
  if (inStock.length === 0) return null;
  if (categoryOf(product) === 'shoes') return sizeToSelect(body, inStock, true);

  const chart = sizeChartFrom(product);
  const usual = sizeToSelect(body, inStock, false);
  if (usual !== null) {
    const check = fitCheck(chart, body, usual);
    if (!check.hasResult || check.isComfortable) return usual;
  }
  const recommended = recommendSize(chart, body);
  if (recommended !== null && inStock.includes(recommended)) {
    if (fitCheck(chart, body, recommended).isComfortable) return recommended;
  }
  return null;
}

/**
 * Whether [product] belongs in [shopper]'s feed, and why. Null if not.
 * shopper: { userId, body, styles, ownedByCategory, followedSellerIds }
 */
function matchProduct(product, shopper) {
  const id = text(product.id);
  const seller = sellerOf(product);
  if (id === '' || seller === '' || seller === shopper.userId) return null;
  if (!shopper.followedSellerIds.has(seller)) return null;

  const category = categoryOf(product);
  let size = '';
  if (SIZED_CATEGORIES.has(category)) {
    const fitting = sizeFor(product, shopper.body);
    if (fitting === null) return null;
    size = fitting;
  } else if (
    (typeof product.stock === 'number' ? product.stock : 1) <= 0 &&
    Object.keys(parseSizeInventory(product)).length === 0
  ) {
    return null;
  }

  const style = matchingStyle(product, shopper.styles);
  const owned = shopper.ownedByCategory[category] || 0;
  const fillsGap =
    category !== '' &&
    category !== 'other' &&
    owned < GAP_BELOW &&
    Object.keys(shopper.ownedByCategory).length > 0;
  if (style === null && !fillsGap) return null;

  return {
    productId: id,
    score: 3 + (style !== null ? 2 : 0) + (fillsGap ? 2 : 0),
    size,
    reasons: [
      size !== '' ? `In your size (${size})` : 'Available now',
      ...(style !== null ? [`Suits your ${style} style`] : []),
      ...(fillsGap ? [`Fills a gap: you don't have any ${category} yet`] : []),
    ],
  };
}

/**
 * Decides what to do with a new card given today's cards (each
 * { id, score, createdAtMillis }): add it, and which card to drop, so a person
 * never has more than [cap] a day and the best ones stay.
 */
function placeCard(existing, card, cap = DAILY_CARDS) {
  if (existing.some((item) => item.id === card.id)) return { add: false, remove: [] };
  if (existing.length < cap) return { add: true, remove: [] };
  const weakest = [...existing].sort(
    (a, b) => a.score - b.score || a.createdAtMillis - b.createdAtMillis,
  )[0];
  return card.score > weakest.score
    ? { add: true, remove: [weakest.id] }
    : { add: false, remove: [] };
}

/** True for a new product, or one that was sold out and has stock again. */
function isNewStock(before, after) {
  if (!after) return false;
  if (!before) return totalStock(after) > 0;
  return totalStock(before) <= 0 && totalStock(after) > 0;
}

export {
  DAILY_CARDS,
  bodyProfileFrom,
  fitCheck,
  isNewStock,
  matchProduct,
  matchingStyle,
  parseSizeInventory,
  placeCard,
  recommendSize,
  sellerOf,
  sizeChartFrom,
  sizeFor,
  totalStock,
};
