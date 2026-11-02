// What counts as a trending look, and who is told (review item E-4).
//
// A look is trending when at least MIN_PEOPLE different people affirmed it in
// the last 24 hours. Counts are never shown to anyone: the push only says a
// look near you is getting attention, which keeps counts owner-only. The best
// look in each city goes to people in that city, at most one push a person a
// day, never the same look twice, and never to its owner or to someone who
// already affirmed it. Pure functions; the job in trendingJob.js does the
// reading and writing.

const MIN_PEOPLE = 3;
const WINDOW_HOURS = 24;

/** "  Harare, Zimbabwe " → "harare" (the same rule as the app). */
const normalizeCity = (value) =>
  String(value === undefined || value === null ? '' : value)
    .split(',')[0]
    .trim()
    .toLowerCase();

const millisOf = (stamp) => {
  if (stamp && typeof stamp.toMillis === 'function') return stamp.toMillis();
  if (stamp instanceof Date) return stamp.getTime();
  return 0;
};

/**
 * Looks affirmed by MIN_PEOPLE or more different people inside the window,
 * best first (most people, then the most recent affirmation). Each result is
 * { postId, ownerId, people, senderIds: Set, latestMillis }.
 */
function trendingLooks(affirmations, now = new Date(), { minPeople = MIN_PEOPLE } = {}) {
  const since = now.getTime() - WINDOW_HOURS * 3600 * 1000;
  const byPost = new Map();
  for (const item of affirmations) {
    if (item.targetType !== 'post' || !item.targetId) continue;
    if (item.moderationState && item.moderationState !== 'clear') continue;
    const at = millisOf(item.createdAt);
    if (at < since || at > now.getTime()) continue;
    if (!item.senderId) continue;
    let entry = byPost.get(item.targetId);
    if (!entry) {
      entry = {
        postId: item.targetId,
        ownerId: item.targetOwnerId || '',
        senderIds: new Set(),
        latestMillis: 0,
      };
      byPost.set(item.targetId, entry);
    }
    entry.senderIds.add(item.senderId);
    entry.latestMillis = Math.max(entry.latestMillis, at);
  }
  return [...byPost.values()]
    .map((entry) => ({ ...entry, people: entry.senderIds.size }))
    .filter((entry) => entry.people >= minPeople)
    .sort((a, b) => b.people - a.people || b.latestMillis - a.latestMillis);
}

/**
 * The best look per place; items with no place are left out. A place is the
 * author's phone-location cell (placeKey "cell:155:-90") or, without one, the
 * city they typed ("city:harare"); older items may carry just a cityKey.
 */
function pickPerCity(items) {
  const best = new Map();
  for (const item of items) {
    const key = item.placeKey || item.cityKey;
    if (!key) continue;
    const current = best.get(key);
    if (
      !current ||
      item.people > current.people ||
      (item.people === current.people && item.latestMillis > current.latestMillis)
    ) {
      best.set(key, item);
    }
  }
  return best;
}

/**
 * Whether [uid] should get the push for [postId]. [user] is their user
 * document, [notice] their record of the last trending push
 * ({ day, postIds }), and [senderIds] who already affirmed the look.
 */
function shouldNotify({ uid, ownerId, senderIds, postId, today, user, notice }) {
  if (uid === ownerId || senderIds.has(uid)) return false;
  if (user && user.notifyTrending === false) return false;
  if (notice) {
    if (notice.day === today) return false;
    if ((notice.postIds || []).includes(postId)) return false;
  }
  return true;
}

export { MIN_PEOPLE, WINDOW_HOURS, normalizeCity, pickPerCity, shouldNotify, trendingLooks };
