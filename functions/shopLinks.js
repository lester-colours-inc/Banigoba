// When a shop shares its stock (review item K-9) to friends, followers or the
// public, tell those people with a notification; sendPushNotification turns
// each into a push. A just-the-link share tells nobody: the shop sends that
// link itself (WhatsApp groups, other apps, QR).
'use strict';

const MAX_PEOPLE = 1000;
const BATCH = 400;

/**
 * Builds the handler for the shop_links/{linkId} create trigger.
 * Returns { told } for tests.
 */
function announceShopLinkHandler(db, FieldValue, logger = console) {
  async function idsIn(path) {
    const snapshot = await db.collection(path).limit(MAX_PEOPLE).get();
    return new Set(snapshot.docs.map((doc) => doc.id));
  }

  return async (event) => {
    const link = event.data?.data();
    if (!link || link.active === false) return { told: 0 };
    const audience = link.audience;
    if (!['friends', 'followers', 'public'].includes(audience)) return { told: 0 };
    const owner = String(link.ownerId || '');
    if (owner === '') return { told: 0 };

    const followers = await idsIn(`users/${owner}/followers`);
    let people = followers;
    if (audience === 'friends') {
      const following = await idsIn(`users/${owner}/following`);
      people = new Set([...followers].filter((id) => following.has(id)));
    }
    people.delete(owner);

    const shopName = String(link.shopName || 'A shop');
    const title = String(link.title || 'their stock');
    const ids = [...people];
    for (let i = 0; i < ids.length; i += BATCH) {
      const batch = db.batch();
      for (const uid of ids.slice(i, i + BATCH)) {
        batch.set(db.collection(`users/${uid}/notifications`).doc(), {
          title: shopName,
          body: `shared ${title}. Try them on and buy.`,
          type: 'shop_link',
          senderId: owner,
          extraData: { linkId: event.params.linkId, fromName: shopName },
          isRead: false,
          timestamp: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
    logger.info(`shop link ${event.params.linkId}: told ${ids.length} people`);
    return { told: ids.length };
  };
}

module.exports = { announceShopLinkHandler };
