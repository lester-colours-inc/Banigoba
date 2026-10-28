// Stores gallery-suggestion consent (E-5) at users/{uid}/private/
// photoSuggestions, which only the person can read or write.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gallery_consent.dart';

/// What the screens need; the real one reads Firestore, tests use a fake.
abstract interface class GalleryConsentStore {
  Future<GalleryConsent> load();
  Future<void> grant();
  Future<void> withdraw();
}

class GalleryConsentService implements GalleryConsentStore {
  GalleryConsentService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _injectedDb = db,
      _injectedAuth = auth;

  final FirebaseFirestore? _injectedDb;
  final FirebaseAuth? _injectedAuth;

  // Looked up when used, so building the service never needs Firebase.
  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = (_injectedAuth ?? FirebaseAuth.instance).currentUser?.uid;
    if (uid == null) return null;
    return (_injectedDb ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('photoSuggestions');
  }

  @override
  Future<GalleryConsent> load() async {
    final doc = _doc;
    if (doc == null) return const GalleryConsent.none();
    try {
      return GalleryConsent.fromMap((await doc.get()).data());
    } on FirebaseException {
      return const GalleryConsent.none();
    }
  }

  Future<void> _save(GalleryConsent consent) async {
    final doc = _doc;
    if (doc == null) return;
    await doc.set({
      ...consent.toMap(),
      'changedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> grant() => _save(GalleryConsent.granted());

  @override
  Future<void> withdraw() => _save(GalleryConsent.granted().withdrawn());
}
