// Exposes authenticated backend operations for the Banigoba app.
const admin = require('firebase-admin');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { matchNewStockHandler } = require('./matchNewStock');
const { runIngest } = require('./content/ingest');
const { notifyTrendingJob } = require('./trendingJob');
const { announceShopLinkHandler } = require('./shopLinks');
const { SOURCES } = require('./content/sources');

admin.initializeApp();
const db = admin.firestore();

exports.sendPushNotification = onDocumentCreated(
  {
    document: 'users/{userId}/notifications/{notificationId}',
    region: 'europe-west1',
  },
  async (event) => {
    const notification = event.data?.data();
    if (!notification) return;

    const tokenSnapshot = await db
      .collection('users')
      .doc(event.params.userId)
      .collection('fcmTokens')
      .get();

    if (tokenSnapshot.empty) return;

    const title =
      typeof notification.title === 'string'
        ? notification.title
        : 'Banigoba';
    const body =
      typeof notification.body === 'string'
        ? notification.body
        : 'You have a new notification.';
    const type =
      typeof notification.type === 'string'
        ? notification.type
        : 'general';
    const extraData =
      notification.extraData && typeof notification.extraData === 'object'
        ? notification.extraData
        : {};
    const pushData = {
      type,
      notificationId: event.params.notificationId,
    };
    Object.entries(extraData).forEach(([key, value]) => {
      if (value === null || value === undefined) return;
      pushData[key] =
        typeof value === 'string' ? value : JSON.stringify(value);
    });

    const tokenDocs = tokenSnapshot.docs.filter((doc) => {
      const token = doc.get('token');
      return typeof token === 'string' && token.length > 0;
    });

    for (let index = 0; index < tokenDocs.length; index += 500) {
      const batch = tokenDocs.slice(index, index + 500);
      const response = await admin.messaging().sendEachForMulticast({
        tokens: batch.map((doc) => doc.get('token')),
        notification: { title, body },
        data: pushData,
        android: {
          priority: 'high',
          notification: {
            title,
            body,
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              alert: { title, body },
              sound: 'default',
            },
          },
        },
      });

      const staleTokenDeletes = [];
      response.responses.forEach((result, responseIndex) => {
        const code = result.error?.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          staleTokenDeletes.push(batch[responseIndex].ref.delete());
        }
      });
      await Promise.all(staleTokenDeletes);
    }
  },
);

exports.generateMakeover = onCall(
  { region: 'europe-west1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'You must be signed in to generate a makeover.',
      );
    }

    const data = request.data;
    const style = typeof data?.style === 'string' ? data.style.trim() : '';
    const imageUrl =
      typeof data?.imageUrl === 'string' ? data.imageUrl.trim() : '';

    if (!style || !imageUrl) {
      throw new HttpsError(
        'invalid-argument',
        'style and imageUrl are required.',
      );
    }

    let parsedImageUrl;
    try {
      parsedImageUrl = new URL(imageUrl);
    } catch (_) {
      throw new HttpsError(
        'invalid-argument',
        'imageUrl must be a valid URL.',
      );
    }

    if (parsedImageUrl.protocol !== 'https:') {
      throw new HttpsError(
        'invalid-argument',
        'imageUrl must use HTTPS.',
      );
    }

    const userId = request.auth.uid;
    const recordRef = db.collection('ai_makeovers').doc();

    // Replace this placeholder with the protected AI provider call.
    const generatedImageUrls = [imageUrl, imageUrl, imageUrl];

    await recordRef.set({
      userId,
      style,
      sourceImageUrl: imageUrl,
      generatedImageUrls,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      recordId: recordRef.id,
      generatedImageUrls,
    };
  },
);

// Daily feed cards (review items D-4, A-6): when a shop adds or restocks a
// piece, write a card for each follower it suits, in their size and style.
exports.matchNewStock = onDocumentWritten(
  {
    document: 'products/{productId}',
    region: 'europe-west1',
    timeoutSeconds: 300,
  },
  matchNewStockHandler(db, admin.firestore.FieldValue),
);

// Fashion-content engine (review items E-2, E-3, F-2): every few hours, read
// the publishers' own feeds and store the fashion stories and events as
// credited link previews in content_items, which the app reads.
exports.refreshFashionContent = onSchedule(
  {
    schedule: 'every 3 hours',
    region: 'europe-west1',
    timeoutSeconds: 300,
  },
  async () => {
    await runIngest({
      db,
      sources: SOURCES,
      now: new Date(),
      FieldValue: admin.firestore.FieldValue,
    });
  },
);

// Trending looks (review item E-4): every evening, tell people in a city about
// the look people there are affirming most. Quiet until a look has been
// affirmed by three different people in a day.
exports.notifyTrendingLooks = onSchedule(
  {
    schedule: 'every day 18:00',
    timeZone: 'Africa/Harare',
    region: 'europe-west1',
    timeoutSeconds: 300,
  },
  async () => {
    await notifyTrendingJob(db, admin.firestore.FieldValue)(new Date());
  },
);

// Shared stock links (review item K-9): when a shop shares to friends,
// followers or the public, tell those people.
exports.announceShopLink = onDocumentCreated(
  {
    document: 'shop_links/{linkId}',
    region: 'europe-west1',
  },
  announceShopLinkHandler(db, admin.firestore.FieldValue),
);
