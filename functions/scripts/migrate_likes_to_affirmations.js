#!/usr/bin/env node
//
// One-off backfill: legacy like records → affirmation documents.
//
// Run this deliberately. It is not wired into deploy, and no application code
// calls it.
//
// WHAT IT DOES
//   Every legacy like found on a post or a saved hair look becomes one
//   affirmation document in /affirmations, sent from the same user, using the
//   universal "Beautiful" expression, and tagged `migratedFromLike: true`.
//
// A CAVEAT WORTH KNOWING
//   A like is not an affirmation. The sender picked a heart, not a word, so
//   this necessarily attributes an expression they never chose. Every record
//   it writes is tagged, so `--revert` can remove exactly the documents this
//   script created and nothing else.
//
// IDEMPOTENT
//   Affirmation ids are deterministic — (targetType, targetId, senderId,
//   definitionId) — so re-running converges instead of duplicating.
//
// USAGE
//   node migrate_likes_to_affirmations.js --dry-run
//   node migrate_likes_to_affirmations.js
//   node migrate_likes_to_affirmations.js --purge-legacy   # after verifying
//   node migrate_likes_to_affirmations.js --revert
//
// Requires GOOGLE_APPLICATION_CREDENTIALS to point at a service account key
// for the target project.

const admin = require('firebase-admin');

const DEFINITION_ID = 'universal.beautiful';
const DEFINITION = {
  emoji: '✨',
  shortLabel: 'Beautiful',
  text: 'Beautiful',
  category: 'beauty_and_presence',
  language: 'en',
};

const BATCH_LIMIT = 400;

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const shouldPurgeLegacy = args.includes('--purge-legacy');
const shouldRevert = args.includes('--revert');

admin.initializeApp();
const db = admin.firestore();

function affirmationId(targetType, targetId, senderId) {
  return `${targetType}__${targetId}__${senderId}__${DEFINITION_ID}`;
}

/** Collects like senders from both the array fields and the subcollection. */
async function likeSendersFor(docRef, data) {
  const senders = new Set();

  for (const field of ['likedBy', 'likes']) {
    const value = data[field];
    if (Array.isArray(value)) {
      for (const entry of value) {
        const id = String(entry || '').trim();
        if (id) senders.add(id);
      }
    }
  }

  const subcollection = await docRef.collection('likes').get();
  for (const like of subcollection.docs) {
    const id = String(like.data().userId || like.id || '').trim();
    if (id) senders.add(id);
  }

  return [...senders];
}

const displayNameCache = new Map();

async function displayNameFor(userId) {
  if (displayNameCache.has(userId)) return displayNameCache.get(userId);

  let name = 'Someone';
  try {
    const user = await db.collection('users').doc(userId).get();
    const stored = user.data()?.displayName;
    if (typeof stored === 'string' && stored.trim()) name = stored.trim();
  } catch (error) {
    console.warn(`  ! could not read displayName for ${userId}: ${error.code}`);
  }

  displayNameCache.set(userId, name);
  return name;
}

class BatchWriter {
  constructor() {
    this.batch = db.batch();
    this.pending = 0;
    this.written = 0;
  }

  async set(ref, data) {
    this.batch.set(ref, data, { merge: false });
    await this._tick();
  }

  async update(ref, data) {
    this.batch.update(ref, data);
    await this._tick();
  }

  async delete(ref) {
    this.batch.delete(ref);
    await this._tick();
  }

  async _tick() {
    this.pending += 1;
    this.written += 1;
    if (this.pending >= BATCH_LIMIT) await this.flush();
  }

  async flush() {
    if (this.pending === 0) return;
    await this.batch.commit();
    this.batch = db.batch();
    this.pending = 0;
  }
}

/** Converts one target's likes. Returns the number of affirmations created. */
async function convertTarget(writer, { docRef, data, targetType, ownerId }) {
  const targetId = docRef.id;
  if (!ownerId) {
    console.warn(`  ! ${targetType}/${targetId} has no owner; skipped`);
    return 0;
  }

  const senders = await likeSendersFor(docRef, data);
  let created = 0;

  for (const senderId of senders) {
    // A user cannot affirm their own look, so a self-like has no equivalent.
    if (senderId === ownerId) continue;

    const ref = db
      .collection('affirmations')
      .doc(affirmationId(targetType, targetId, senderId));

    if (isDryRun) {
      created += 1;
      continue;
    }

    const existing = await ref.get();
    if (existing.exists) continue;

    const createdAt =
      data.publishedAt || data.createdAt || admin.firestore.Timestamp.now();

    await writer.set(ref, {
      senderId,
      senderName: await displayNameFor(senderId),
      targetType,
      targetId,
      targetOwnerId: ownerId,
      definitionId: DEFINITION_ID,
      ...DEFINITION,
      meaning: '',
      personalMessage: '',
      moderationState: 'clear',
      migratedFromLike: true,
      createdAt,
    });
    created += 1;
  }

  return created;
}

async function eachLegacyTarget(handler) {
  const posts = await db.collection('posts').get();
  for (const doc of posts.docs) {
    const data = doc.data();
    await handler({
      docRef: doc.ref,
      data,
      targetType: 'post',
      ownerId: String(data.authorId || data.authorID || '').trim(),
    });
  }

  const users = await db.collection('users').get();
  for (const user of users.docs) {
    const looks = await user.ref.collection('hairStyles').get();
    for (const look of looks.docs) {
      await handler({
        docRef: look.ref,
        data: look.data(),
        targetType: 'hair_look',
        ownerId: user.id,
      });
    }
  }
}

async function migrate() {
  const writer = new BatchWriter();
  let created = 0;
  let targets = 0;

  await eachLegacyTarget(async (target) => {
    targets += 1;
    created += await convertTarget(writer, target);
  });

  await writer.flush();

  console.log(`\nScanned ${targets} targets.`);
  console.log(
    isDryRun
      ? `Would create ${created} affirmations. Nothing was written.`
      : `Created ${created} affirmations.`
  );

  if (shouldPurgeLegacy) await purgeLegacy();
  else if (!isDryRun) {
    console.log(
      '\nLegacy like fields were left in place. Verify the affirmations, ' +
        'then re-run with --purge-legacy to remove them.'
    );
  }
}

/** Removes legacy like fields and subcollections. Destructive. */
async function purgeLegacy() {
  console.log('\nPurging legacy like data...');
  const writer = new BatchWriter();
  let cleared = 0;

  await eachLegacyTarget(async ({ docRef, data }) => {
    const hasFields = ['likeCount', 'likedBy', 'likes'].some(
      (field) => data[field] !== undefined
    );

    if (hasFields) {
      await writer.update(docRef, {
        likeCount: admin.firestore.FieldValue.delete(),
        likedBy: admin.firestore.FieldValue.delete(),
        likes: admin.firestore.FieldValue.delete(),
      });
      cleared += 1;
    }

    const subcollection = await docRef.collection('likes').get();
    for (const like of subcollection.docs) {
      await writer.delete(like.ref);
    }
  });

  await writer.flush();
  console.log(`Cleared legacy like fields on ${cleared} documents.`);
}

/** Deletes exactly the documents this script created. */
async function revert() {
  const snapshot = await db
    .collection('affirmations')
    .where('migratedFromLike', '==', true)
    .get();

  console.log(`Found ${snapshot.size} migrated affirmations.`);
  if (isDryRun || snapshot.empty) {
    console.log('Nothing was written.');
    return;
  }

  const writer = new BatchWriter();
  for (const doc of snapshot.docs) {
    await writer.delete(doc.ref);
  }
  await writer.flush();
  console.log(`Deleted ${snapshot.size} migrated affirmations.`);
}

async function main() {
  console.log(`Project: ${admin.app().options.projectId || '(from ADC)'}`);
  if (isDryRun) console.log('Mode: DRY RUN — no writes\n');

  if (shouldRevert) await revert();
  else await migrate();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('\nMigration failed:', error);
    process.exit(1);
  });
