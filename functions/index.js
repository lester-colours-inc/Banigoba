// Exposes an HTTP function that proxies protected AI makeover requests.
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.generateMakeover = functions.region('europe-west1').https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send({ error: 'Method not allowed. Use POST.' });
    return;
  }

  const authHeader = req.get('Authorization') || req.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).send({ error: 'Missing or invalid Authorization header.' });
    return;
  }

  const idToken = authHeader.split('Bearer ')[1];
  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    res.status(401).send({ error: 'Invalid authentication token.' });
    return;
  }

  const { userId, style, imageUrl } = req.body || {};
  if (!userId || !style || !imageUrl) {
    res.status(400).send({ error: 'userId, style, and imageUrl are required.' });
    return;
  }

  if (decodedToken.uid !== userId) {
    res.status(403).send({ error: 'User ID does not match the authenticated user.' });
    return;
  }

  const timestamp = Date.now();
  const recordId = `makeover_${userId}_${timestamp}`;
  const generatedImageUrls = [
    imageUrl,
    imageUrl,
    imageUrl,
  ];

  const record = {
    userId,
    style,
    sourceImageUrl: imageUrl,
    generatedImageUrls,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('ai_makeovers').doc(recordId).set(record);

  res.status(200).send({ recordId, generatedImageUrls });
});
