// When a shop adds stock (or restocks a sold-out piece), decide for each
// follower whether it belongs in their My Daily Dress Up feed, and write a
// card to users/{follower}/feedCards. The rules are in feedMatching.js; the
// app only has to read today's cards (see FeedMatchesService).
'use strict';

const {
  bodyProfileFrom,
  isNewStock,
  matchProduct,
  placeCard,
  sellerOf,
} = require('./feedMatching');

// One shop's followers handled per stock event, and how many at a time.
const MAX_FOLLOWERS = 1000;
const CONCURRENCY = 20;

const utcDay = (date = new Date()) => date.toISOString().slice(0, 10);

function ownedCounts(wardrobeDocs) {
  const counts = {};
  for (const doc of wardrobeDocs) {
    const category = String(doc.get('category') || '').trim().toLowerCase();
    if (category !== '') counts[category] = (counts[category] || 0) + 1;
  }
  return counts;
}

/**
 * Builds the handler for the products/{productId} trigger.
 * @param {FirebaseFirestore.Firestore} db
 * @param {{ serverTimestamp: () => unknown }} FieldValue
 * @param {{ info: Function, warn: Function }} logger
 */
function matchNewStockHandler(db, FieldValue, logger = console) {
  async function cardFor(followerId, product, today) {
    const user = db.collection('users').doc(followerId);

    // "Not for me" is remembered forever.
    if ((await user.collection('feedDismissed').doc(product.id).get()).exists) return false;

    const [profile, bodyDoc, wardrobe] = await Promise.all([
      user.get(),
      user.collection('private').doc('bodyProfile').get(),
      db.collection('user_products').where('userId', '==', followerId).get(),
    ]);
    const styles = profile.get('stylePreferences');
    const match = matchProduct(product, {
      userId: followerId,
      body: bodyProfileFrom(bodyDoc.data()),
      styles: Array.isArray(styles) ? styles.map(String) : [],
      ownedByCategory: ownedCounts(wardrobe.docs),
      followedSellerIds: new Set([sellerOf(product)]),
    });
    if (match === null) return false;

    const todays = await user.collection('feedCards').where('day', '==', today).get();
    const decision = placeCard(
      todays.docs.map((doc) => ({
        id: doc.id,
        score: Number(doc.get('score')) || 0,
        createdAtMillis: doc.get('createdAt')?.toMillis?.() ?? 0,
      })),
      { id: product.id, score: match.score },
    );
    if (!decision.add) return false;

    const batch = db.batch();
    for (const id of decision.remove) {
      batch.delete(user.collection('feedCards').doc(id));
    }
    batch.set(user.collection('feedCards').doc(product.id), {
      productId: product.id,
      sellerId: sellerOf(product),
      product,
      score: match.score,
      size: match.size,
      reasons: match.reasons,
      day: today,
      createdAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return true;
  }

  // How far a piece got, for the shop only: a count, never who. A restock
  // adds to the total.
  async function recordReach(product, reached, followers) {
    const ref = db.collection('product_insights').doc(product.id);
    const before = (await ref.get()).data();
    const batch = db.batch();
    batch.set(ref, {
      sellerId: sellerOf(product),
      reach: ((before && before.reach) || 0) + reached,
      followers,
      updatedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  return async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!isNewStock(before, after)) return;

    const product = { ...after, id: event.params.productId };
    const seller = sellerOf(product);
    if (seller === '') return;

    const followers = await db
      .collection('users')
      .doc(seller)
      .collection('followers')
      .limit(MAX_FOLLOWERS)
      .get();
    const today = utcDay();
    let written = 0;
    for (let i = 0; i < followers.docs.length; i += CONCURRENCY) {
      const group = followers.docs.slice(i, i + CONCURRENCY);
      const results = await Promise.allSettled(
        group.map((follower) => cardFor(follower.id, product, today)),
      );
      for (const result of results) {
        if (result.status === 'rejected') {
          logger.warn('feed card failed', result.reason);
        } else if (result.value) {
          written += 1;
        }
      }
    }
    await recordReach(product, written, followers.size);
    logger.info(`matched ${product.id} for ${written} of ${followers.size} followers`);
  };
}

module.exports = { matchNewStockHandler, utcDay };
