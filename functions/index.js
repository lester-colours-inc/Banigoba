// Exposes authenticated backend operations for the Banigoba app.
const admin = require('firebase-admin');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

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
