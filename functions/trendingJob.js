// Once a day: find the looks people are affirming, and tell people in the
// same city about the best one (review item E-4). The rules are in
// trending.js; the push itself is sent by sendPushNotification when the
// notification document below is created.
'use strict';

const { normalizeCity, pickPerCity, shouldNotify, trendingLooks, WINDOW_HOURS } = require('./trending');

const MAX_AFFIRMATIONS = 5000;
const MAX_LOOKS = 50;
const MAX_PEOPLE_PER_CITY = 500;
const BATCH = 200;
const REMEMBER_POSTS = 20;

const utcDay = (date) => date.toISOString().slice(0, 10);

const isPublic = (post) =>
  post.visibility === 'public' || (post.visibility === undefined && post.isPublic === true);

/**
 * Builds the job. Returns async (now) => { notified, cities }.
 * @param {FirebaseFirestore.Firestore} db
 * @param {{ serverTimestamp: () => unknown }} FieldValue
 */
function notifyTrendingJob(db, FieldValue, logger = console) {
  async function candidates(now) {
    const since = new Date(now.getTime() - WINDOW_HOURS * 3600 * 1000);
    const snapshot = await db
      .collection('affirmations')
      .where('createdAt', '>=', since)
      .limit(MAX_AFFIRMATIONS)
      .get();
    const looks = trendingLooks(
      snapshot.docs.map((doc) => doc.data()),
      now,
    ).slice(0, MAX_LOOKS);

    const items = [];
    for (const look of looks) {
      const post = await db.collection('posts').doc(look.postId).get();
      if (!post.exists || !isPublic(post.data())) continue;
      const ownerId = post.data().authorId || look.ownerId;
      const owner = await db.collection('users').doc(ownerId).get();
      const data = owner.exists ? owner.data() : {};
      const cityKey = data.cityKey || normalizeCity(data.city);
      items.push({
        ...look,
        ownerId,
        // Their phone-location area when they share one, else their city.
        placeKey: data.areaCell
          ? `cell:${data.areaCell}`
          : cityKey
            ? `city:${cityKey}`
            : '',
      });
    }
    return items;
  }

  return async (now = new Date()) => {
    const today = utcDay(now);
    const best = pickPerCity(await candidates(now));
    let notified = 0;

    for (const [placeKey, look] of best) {
      const isCell = placeKey.startsWith('cell:');
      const value = placeKey.slice(placeKey.indexOf(':') + 1);
      const people = await db
        .collection('users')
        .where(isCell ? 'areaCell' : 'cityKey', '==', value)
        .limit(MAX_PEOPLE_PER_CITY)
        .get();

      for (let i = 0; i < people.docs.length; i += BATCH) {
        const batch = db.batch();
        let writes = 0;
        for (const person of people.docs.slice(i, i + BATCH)) {
          try {
            const noticeRef = db.collection('users').doc(person.id).collection('private').doc('trendingNotice');
            const notice = (await noticeRef.get()).data();
            if (
              !shouldNotify({
                uid: person.id,
                ownerId: look.ownerId,
                senderIds: look.senderIds,
                postId: look.postId,
                today,
                user: person.data(),
                notice,
              })
            ) {
              continue;
            }
            batch.set(db.collection('users').doc(person.id).collection('notifications').doc(), {
              title: isCell ? 'Trending near you' : `Trending in ${person.data().city || value}`,
              body: 'A look people near you are talking about.',
              type: 'trending_look',
              senderId: '',
              extraData: { postId: look.postId },
              isRead: false,
              timestamp: FieldValue.serverTimestamp(),
            });
            batch.set(noticeRef, {
              day: today,
              postIds: [...((notice && notice.postIds) || []), look.postId].slice(-REMEMBER_POSTS),
            });
            writes += 1;
          } catch (error) {
            logger.warn(`trending notice failed for ${person.id}`, error);
          }
        }
        if (writes > 0) await batch.commit();
        notified += writes;
      }
    }
    logger.info(`trending: ${notified} people told about ${best.size} places`);
    return { notified, cities: best.size };
  };
}

module.exports = { notifyTrendingJob };
