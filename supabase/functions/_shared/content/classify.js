// Turns a feed item into a stored link preview and tags it. Only the title,
// a link to the source's own picture, the source's name and the link itself
// are kept: no article text is stored and no picture is copied, so every
// card credits and opens the source.

import crypto from 'node:crypto';

const KEEP_DAYS = 30;
const MAX_TITLE = 180;
const DAY_MS = 24 * 60 * 60 * 1000;

const FASHION =
  /\b(fashion|style[ds]?|styling|stylist|runway|catwalk|couture|designers?|outfits?|wardrobe|dress(es|ed)?|gowns?|menswear|womenswear|streetwear|apparel|clothing|clothes|garments?|textiles?|boutique|tailor(ing|ed)?|hair ?styles?|braids?|wigs?|sneakers?|ankara|kente|african print|collection|lookbook|models?|beauty|makeup|jewell?ery|accessor(y|ies))\b/i;

// Something happening, rather than being reported. Pop-ups, expos, festivals
// and galas are events by nature; a fashion week, show or showcase counts
// only when the title also announces it (returns, tickets, to host...), so a
// review of a show that has passed stays news. Only the title is read: a
// "Fashion Week" category on a collection review says nothing about an event.
const EVENT_ALWAYS = /\b(pop-?up|expo|festival|gala)\b/i;
const EVENT_NAMED =
  /\b(fashion week|fashion show|runway show|catwalk show|showcase|trade show|fashion awards|fashion market|fashion night)\b/i;
const EVENT_CUE =
  /\b(returns?|to host|hosts?|will|announces?|announced|opens?|launch(es)?|set to|unveils?|dates?|tickets?|call for|applications?|save the date|coming|upcoming|calling|go on sale|on sale)\b/i;

const PLACES = [
  ['harare', /\bharare\b/i],
  ['bulawayo', /\bbulawayo\b/i],
  ['zimbabwe', /\b(zimbabwe|zimbabwean|zim)\b/i],
  ['lagos', /\blagos\b/i],
  ['nigeria', /\bnigeria(n)?\b/i],
  ['south-africa', /\bsouth africa(n)?\b/i],
  ['johannesburg', /\bjohannesburg\b/i],
  ['cape-town', /\bcape town\b/i],
  ['nairobi', /\bnairobi\b/i],
  ['kenya', /\bkenya(n)?\b/i],
  ['ghana', /\b(ghana(ian)?|accra)\b/i],
  ['london', /\blondon\b/i],
  ['paris', /\bparis\b/i],
  ['milan', /\bmilan\b/i],
  ['new-york', /\bnew york\b/i],
];

const TOPICS = [
  ['african-print', /\b(ankara|kente|african print|afrochic|afro-chic|dashiki)\b/i],
  ['wedding', /\b(wedding|bridal|bride)\b/i],
  ['streetwear', /\bstreetwear\b/i],
  ['menswear', /\b(menswear|men's|mens)\b/i],
  ['hair', /\b(hair ?styles?|braids?|natural hair|wigs?|locs)\b/i],
  ['sustainability', /\b(sustainab\w*|second-?hand|thrift\w*|upcycl\w*)\b/i],
];

const MONTHS = {
  jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5,
  jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11,
};
const MONTH = '(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)';
const ORD = '(?:st|nd|rd|th)?';
// "12 November", "12th Nov", "12-14 November", "12 – 14 November 2027".
const DAY_MONTH = new RegExp(
  `\\b(\\d{1,2})${ORD}(?:\\s*[–-]\\s*\\d{1,2}${ORD})?\\s+${MONTH}\\b(?:\\s+(\\d{4}))?`,
  'i',
);
// "November 12", "Nov 12th", "November 12-14".
const MONTH_DAY = new RegExp(
  `\\b${MONTH}\\s+(\\d{1,2})${ORD}\\b(?:\\s*[–-]\\s*\\d{1,2}${ORD})?(?:,?\\s+(\\d{4}))?`,
  'i',
);
const DAY_MS_ = 24 * 60 * 60 * 1000;
const MAX_AHEAD_DAYS = 400;
const JUST_PAST_DAYS = 30;

const TRACKING = /^(utm_|fbclid$|gclid$|mc_|ref$|igshid$)/i;

const textOf = (item) => `${item.title} ${(item.categories || []).join(' ')}`;

const isFashion = (item) => FASHION.test(textOf(item));

const kindOf = (item) => {
  const title = String(item.title || '');
  return EVENT_ALWAYS.test(title) || (EVENT_NAMED.test(title) && EVENT_CUE.test(title)) ? 'event' : 'news';
};

const placesOf = (item) => PLACES.filter(([, pattern]) => pattern.test(textOf(item))).map(([key]) => key);

const topicsOf = (item) => TOPICS.filter(([, pattern]) => pattern.test(textOf(item))).map(([key]) => key);

/**
 * The day an event starts, when the title says it ("opens on 12 November"):
 * midnight UTC of that day, or null. A day with no month, or a month with no
 * day ("returns in March"), gives null. With no year given, the next time
 * that day comes round counts, unless it has only just passed (a report on a
 * show that happened), which gives null, and nothing further than
 * MAX_AHEAD_DAYS away is believed.
 */
function eventDateOf(title, now = new Date()) {
  const text = String(title || '');
  let day;
  let month;
  let year;
  let match = DAY_MONTH.exec(text);
  if (match) {
    day = Number(match[1]);
    month = MONTHS[match[2].slice(0, 3).toLowerCase()];
    year = match[3] ? Number(match[3]) : null;
  } else if ((match = MONTH_DAY.exec(text))) {
    month = MONTHS[match[1].slice(0, 3).toLowerCase()];
    day = Number(match[2]);
    year = match[3] ? Number(match[3]) : null;
  } else {
    return null;
  }
  const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const build = (y) => {
    const date = new Date(Date.UTC(y, month, day));
    return date.getUTCMonth() === month && date.getUTCDate() === day ? date : null;
  };
  let date = build(year || now.getUTCFullYear());
  if (date === null) return null;
  const behind = (today - date.getTime()) / DAY_MS_;
  if (behind > 1) {
    if (year || behind <= JUST_PAST_DAYS) return null;
    date = build(now.getUTCFullYear() + 1);
    if (date === null) return null;
  }
  return (date.getTime() - today) / DAY_MS_ > MAX_AHEAD_DAYS ? null : date;
}

/** An http(s) link without tracking parameters or a fragment, or ''. */
function cleanUrl(value) {
  let url;
  try {
    url = new URL(String(value).trim());
  } catch (_) {
    return '';
  }
  if (url.protocol !== 'https:' && url.protocol !== 'http:') return '';
  url.hash = '';
  for (const key of [...url.searchParams.keys()]) {
    if (TRACKING.test(key)) url.searchParams.delete(key);
  }
  return url.toString();
}

const itemId = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 20);

const secureImage = (value) => {
  const url = String(value || '').trim();
  return /^https:\/\//i.test(url) ? url : '';
};

/**
 * The document to store for [item] from [source], or null when it should be
 * skipped: no usable link, too old, or not about fashion on a general feed.
 */
function toDoc(item, source, now = new Date()) {
  const url = cleanUrl(item.link);
  if (url === '') return null;
  if (source.requireFashion && !isFashion(item)) return null;

  let publishedAt = item.publishedAt instanceof Date ? item.publishedAt : now;
  if (publishedAt.getTime() > now.getTime()) publishedAt = now;
  if (now.getTime() - publishedAt.getTime() > KEEP_DAYS * DAY_MS) return null;

  const kind = kindOf(item);
  const startsAt = kind === 'event' ? eventDateOf(item.title, now) : null;
  const expiresAt = new Date(
    Math.max(
      publishedAt.getTime() + KEEP_DAYS * DAY_MS,
      startsAt ? startsAt.getTime() + DAY_MS : 0,
    ),
  );

  return {
    id: itemId(url),
    title: String(item.title).trim().slice(0, MAX_TITLE),
    url,
    imageUrl: secureImage(item.imageUrl),
    sourceId: source.id,
    sourceName: source.name,
    region: source.region || 'intl',
    kind,
    places: placesOf(item),
    topics: topicsOf(item),
    publishedAt,
    ...(startsAt ? { startsAt } : {}),
    expiresAt,
  };
}

export { KEEP_DAYS, cleanUrl, eventDateOf, isFashion, itemId, kindOf, placesOf, toDoc, topicsOf };
