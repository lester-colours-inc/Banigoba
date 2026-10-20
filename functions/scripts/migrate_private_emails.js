#!/usr/bin/env node
//
// One-off backfill: move emails off public user profiles (October 2026
// review, U-5).
//
// Run this deliberately. It is not wired into deploy, and no application code
// calls it. The app already moves the email on every sign-in; this covers
// users who do not sign in again.
//
// WHAT IT DOES
//   For every users/{uid} document that still has an `email` field:
//     - writes it to users/{uid}/private/account (owner-only),
//     - registers emailLookup/{sha256(lower-cased email)} -> { uid },
//     - deletes `email` from the public users/{uid} document.
//   The lookup key matches emailLookupKey() in
//   lib/data/services/account_privacy_service.dart.
//
// IDEMPOTENT
//   Re-running finds nothing left to move.
//
// USAGE
//   node migrate_private_emails.js --dry-run
//   node migrate_private_emails.js
//
// Requires GOOGLE_APPLICATION_CREDENTIALS to point at a service account key
// for the target project.

const crypto = require('crypto');
const admin = require('firebase-admin');

const BATCH_LIMIT = 400;
const isDryRun = process.argv.slice(2).includes('--dry-run');

admin.initializeApp();
const db = admin.firestore();

/**
 * @param {string} email
 * @returns {string} the emailLookup document id for this address
 */
function emailLookupKey(email) {
  return crypto
    .createHash('sha256')
    .update(email.trim().toLowerCase(), 'utf8')
    .digest('hex');
}

async function main() {
  const users = await db.collection('users').get();
  const withEmail = users.docs.filter((doc) => {
    const email = doc.get('email');
    return typeof email === 'string' && email.trim() !== '';
  });
  process.stdout.write(
    `${withEmail.length} of ${users.size} public profiles still carry an email.\n`,
  );
  if (isDryRun || withEmail.length === 0) return;

  let batch = db.batch();
  let pending = 0;
  for (const doc of withEmail) {
    const email = doc.get('email').trim();
    batch.set(
      doc.ref.collection('private').doc('account'),
      { email, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    batch.set(db.collection('emailLookup').doc(emailLookupKey(email)), {
      uid: doc.id,
    });
    batch.update(doc.ref, { email: admin.firestore.FieldValue.delete() });
    pending += 3;
    if (pending >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  process.stdout.write(`Moved ${withEmail.length} emails to private records.\n`);
}

main().catch((error) => {
  process.stderr.write(`Migration failed: ${error.stack || error}\n`);
  process.exitCode = 1;
});
