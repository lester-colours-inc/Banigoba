// Once a day: find the looks people are affirming, and tell people in the same
// place about the best one (review item E-4). The rules are in
// _shared/trending.js; the push itself is sent by send-push when the
// notification row below is added. Called by pg_cron through pg_net.
import {
  normalizeCity,
  pickPerCity,
  shouldNotify,
  trendingLooks,
  WINDOW_HOURS,
} from '../_shared/trending.js';
import { isServiceCaller, json, serviceClient, utcDay } from '../_shared/server.ts';

const MAX_AFFIRMATIONS = 5000;
const MAX_LOOKS = 50;
const MAX_PEOPLE_PER_PLACE = 500;
const REMEMBER_POSTS = 20;

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

Deno.serve(async (req) => {
  if (!isServiceCaller(req)) return json({ error: 'forbidden' }, 403);
  const db = serviceClient();
  const now = new Date();
  const today = utcDay(now);

  const since = new Date(now.getTime() - WINDOW_HOURS * 3600 * 1000).toISOString();
  const { data: affirmations } = await db
    .from('affirmations')
    .select('target_type, target_id, target_owner_id, sender_id, moderation_state, created_at')
    .gte('created_at', since)
    .limit(MAX_AFFIRMATIONS);
  const looks = trendingLooks(
    (affirmations ?? []).map((a: Row) => ({
      targetType: a.target_type,
      targetId: a.target_id,
      targetOwnerId: a.target_owner_id,
      senderId: a.sender_id,
      moderationState: a.moderation_state,
      createdAt: new Date(a.created_at),
    })),
    now,
  ).slice(0, MAX_LOOKS);

  const items: Row[] = [];
  for (const look of looks) {
    const { data: post } = await db
      .from('posts')
      .select('author_id, visibility')
      .eq('id', look.postId)
      .maybeSingle();
    if (!post || post.visibility !== 'public') continue;
    const ownerId = post.author_id ?? look.ownerId;
    const { data: owner } = await db
      .from('profiles')
      .select('city, city_key, area_cell')
      .eq('id', ownerId)
      .maybeSingle();
    const cityKey = owner?.city_key || normalizeCity(owner?.city);
    items.push({
      ...look,
      ownerId,
      // Their phone-location area when they share one, else their city.
      placeKey: owner?.area_cell ? `cell:${owner.area_cell}` : cityKey ? `city:${cityKey}` : '',
    });
  }

  const best = pickPerCity(items);
  let notified = 0;
  for (const [placeKey, look] of best) {
    const isCell = placeKey.startsWith('cell:');
    const value = placeKey.slice(placeKey.indexOf(':') + 1);
    const { data: people } = await db
      .from('profiles')
      .select('id, city, notify_trending')
      .eq(isCell ? 'area_cell' : 'city_key', value)
      .limit(MAX_PEOPLE_PER_PLACE);

    for (const person of people ?? []) {
      try {
        const { data: notice } = await db
          .from('trending_notices')
          .select('day, post_ids')
          .eq('user_id', person.id)
          .maybeSingle();
        const ok = shouldNotify({
          uid: person.id,
          ownerId: look.ownerId,
          senderIds: look.senderIds,
          postId: look.postId,
          today,
          user: { notifyTrending: person.notify_trending },
          notice: notice ? { day: notice.day, postIds: notice.post_ids ?? [] } : null,
        });
        if (!ok) continue;
        await db.from('notifications').insert({
          user_id: person.id,
          sender_id: null,
          type: 'trending_look',
          title: isCell ? 'Trending near you' : `Trending in ${person.city || value}`,
          body: 'A look people near you are talking about.',
          extra_data: { postId: look.postId },
        });
        await db.from('trending_notices').upsert({
          user_id: person.id,
          day: today,
          post_ids: [...(notice?.post_ids ?? []), look.postId].slice(-REMEMBER_POSTS),
        });
        notified += 1;
      } catch (error) {
        console.warn(`trending notice failed for ${person.id}`, error);
      }
    }
  }
  console.info(`trending: ${notified} people told about ${best.size} places`);
  return json({ notified, places: best.size });
});
