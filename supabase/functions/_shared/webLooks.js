// Web look search: the checks on the question asked and the clean-up of the
// image search answer. Kept apart from the Edge Function so it can be tested
// with `node --test`.
import { isAllowedImageUrl } from './aiJobs.js';

export const WEB_LOOK_LIMITS = Object.freeze({
  queryChars: 100,
  results: 40,
  titleChars: 120,
});

/** The question, trimmed and with runs of spaces collapsed, or '' if unusable. */
export function cleanQuery(raw) {
  if (typeof raw !== 'string') return '';
  const query = raw.replace(/\s+/g, ' ').trim();
  if (query.length < 2 || query.length > WEB_LOOK_LIMITS.queryChars) return '';
  return query;
}

const text = (value) => (typeof value === 'string' ? value.trim() : '');

/**
 * Turns a Brave Image Search answer into the looks the app shows: each with
 * a full image and a thumbnail that the AI job may fetch (public HTTPS only),
 * de-duplicated by image address.
 */
export function toWebLooks(answer) {
  const results = Array.isArray(answer?.results) ? answer.results : [];
  const seen = new Set();
  const looks = [];
  for (const result of results) {
    const imageUrl = text(result?.properties?.url);
    const thumbnailUrl = text(result?.thumbnail?.src) || imageUrl;
    if (!isAllowedImageUrl(imageUrl) || !isAllowedImageUrl(thumbnailUrl)) continue;
    if (seen.has(imageUrl)) continue;
    seen.add(imageUrl);
    const pageUrl = text(result?.url);
    looks.push({
      imageUrl,
      thumbnailUrl,
      title: text(result?.title).slice(0, WEB_LOOK_LIMITS.titleChars),
      source: text(result?.source) || hostOf(pageUrl) || hostOf(imageUrl),
      pageUrl: pageUrl.startsWith('https://') ? pageUrl : '',
    });
    if (looks.length >= WEB_LOOK_LIMITS.results) break;
  }
  return looks;
}

function hostOf(raw) {
  try {
    return new URL(raw).hostname.replace(/^www\./, '');
  } catch {
    return '';
  }
}
