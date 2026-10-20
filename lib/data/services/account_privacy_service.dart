// Keeps a user's email off their public profile (October 2026 review, U-5).
//
// users/{uid} is readable by every signed-in user, so the email lives in
// users/{uid}/private/account (readable by its owner only). People who already
// know someone's full address can still find them: emailLookup/{hash} maps
// a SHA-256 of the lower-cased email to the uid, and can be fetched by exact
// key but never listed (see firestore.rules).
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// The emailLookup key for [email]: SHA-256 of the trimmed, lower-cased
/// address, so the stored key does not reveal the address.
String emailLookupKey(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

/// Whether [text] looks like a whole email address, worth a lookup.
bool looksLikeEmail(String text) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim());

class AccountPrivacyService {
  AccountPrivacyService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _account(String userId) =>
      _db.collection('users').doc(userId).collection('private').doc('account');

  /// Stores [email] privately, registers its lookup, and removes any email
  /// from the public profile. Safe to call on every sign-in.
  Future<void> secureEmail({
    required String userId,
    required String email,
  }) async {
    final address = email.trim();
    final batch = _db.batch();
    if (address.isNotEmpty) {
      batch.set(_account(userId), {
        'email': address,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(_db.collection('emailLookup').doc(emailLookupKey(address)), {
        'uid': userId,
      });
    }
    batch.set(_db.collection('users').doc(userId), {
      'email': FieldValue.delete(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// The uid registered for exactly [email], or null.
  Future<String?> findUserByEmail(String email) async {
    if (!looksLikeEmail(email)) return null;
    final doc = await _db
        .collection('emailLookup')
        .doc(emailLookupKey(email))
        .get();
    final uid = doc.data()?['uid'];
    return uid is String && uid.isNotEmpty ? uid : null;
  }
}
