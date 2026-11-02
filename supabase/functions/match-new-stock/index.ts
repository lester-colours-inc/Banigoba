// When a shop adds stock (or restocks a sold-out piece), decide for each
// follower whether it belongs in their My Daily Dress Up feed and write a card.
// The rules are in _shared/feedMatching.js; the app only reads today's cards.
// Called by the database (pg_net) after a product is added or its stock changes.
import {
  bodyProfileFrom,
  isNewStock,
  matchProduct,
  placeCard,
  sellerOf,
} from '../_shared/feedMatching.js';
import { productDoc } from '../_shared/rows.js';
import { inGroups, isServiceCaller, json, serviceClient, utcDay } from '../_shared/server.ts';

const MAX_FOLLOWERS = 1000;
const CONCURRENCY = 20;

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

async function cardFor(db: ReturnType<typeof serviceClient>, followerId: string, product: Row, today: string) {
  // "Not for me" is remembered forever.
  const { data: dismissed } = await db
    .from('feed_dismissed')
    .select('card_id')
    .eq('user_id', followerId)
    .eq('card_id', product.id)
    .maybeSingle();
  if (dismissed) return false;

  const [profile, body, wardrobe] = await Promise.all([
    db.from('profiles').select('style_preferences').eq('id', followerId).maybeSingle(),
    db.from('body_profiles').select('data').eq('user_id', followerId).maybeSingle(),
    db.from('user_products').select('category').eq('user_id', followerId),
  ]);
  const owned: Record<string, number> = {};
  for (const item of wardrobe.data ?? []) {
    const category = String(item.category ?? '').trim().toLowerCase();
    if (category) owned[category] = (owned[category] ?? 0) + 1;
  }
  const styles = profile.data?.style_preferences;
  const match = matchProduct(product, {
    userId: followerId,
    body: bodyProfileFrom(body.data?.data),
    styles: Array.isArray(styles) ? styles.map(String) : [],
    ownedByCategory: owned,
    followedSellerIds: new Set([sellerOf(product)]),
  });
  if (match === null) return false;

  const { data: existing } = await db
    .from('feed_cards')
    .select('id, created_at, data')
    .eq('user_id', followerId)
    .eq('data->>day', today);
  const decision = placeCard(
    (existing ?? []).map((card: Row) => ({
      id: card.id,
      score: Number(card.data?.score) || 0,
      createdAtMillis: Date.parse(card.created_at) || 0,
    })),
    { id: product.id, score: match.score },
  );
  if (!decision.add) return false;

  if (decision.remove.length) {
    await db.from('feed_cards').delete().eq('user_id', followerId).in('id', decision.remove);
  }
  const { error } = await db.from('feed_cards').upsert({
    id: product.id,
    user_id: followerId,
    kind: 'newStock',
    data: {
      productId: product.id,
      sellerId: sellerOf(product),
      product,
      score: match.score,
      size: match.size,
      reasons: match.reasons,
      day: today,
    },
    created_at: new Date().toISOString(),
  });
  if (error) throw error;
  return true;
}

Deno.serve(async (req) => {
  if (!isServiceCaller(req)) return json({ error: 'forbidden' }, 403);
  const { record, old_record: oldRecord } = await req.json();
  if (!record) return json({ matched: 0 });

  const before = oldRecord ? productDoc(oldRecord) : null;
  const product = productDoc(record);
  if (!isNewStock(before, product)) return json({ matched: 0 });
  const seller = sellerOf(product);
  if (seller === '') return json({ matched: 0 });

  const db = serviceClient();
  const { data: followers } = await db
    .from('follows')
    .select('follower_id')
    .eq('followee_id', seller)
    .limit(MAX_FOLLOWERS);
  const people = (followers ?? []).map((row: Row) => row.follower_id as string);
  const today = utcDay();

  let written = 0;
  const results = await inGroups(people, CONCURRENCY, (id) => cardFor(db, id, product, today));
  for (const result of results) {
    if (result.status === 'rejected') console.warn('feed card failed', result.reason);
    else if (result.value) written += 1;
  }

  // How far a piece got, for the shop only: a count, never who. A restock
  // adds to the total.
  const { data: before2 } = await db
    .from('product_insights')
    .select('reach')
    .eq('product_id', product.id)
    .maybeSingle();
  await db.from('product_insights').upsert({
    product_id: product.id,
    seller_id: seller,
    reach: (before2?.reach ?? 0) + written,
    followers: people.length,
    updated_at: new Date().toISOString(),
  });
  console.info(`matched ${product.id} for ${written} of ${people.length} followers`);
  return json({ matched: written, followers: people.length });
});
