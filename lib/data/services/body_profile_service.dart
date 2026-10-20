// Loads and saves a user's personal profile details (BodyProfile).
//
// Stored at users/{uid}/private/bodyProfile. The user document itself is
// readable by every signed-in user (see firestore.rules), so measurements and
// body photos are never written there; everything under a user's document
// other than the public subcollections is owner-only through the rules'
// catch-all. The photos live under userImages/{uid}/, also owner-only.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/body_profile.dart';
import 'storage_service.dart';

class BodyProfileService {
  BodyProfileService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('private')
      .doc('bodyProfile');

  Future<BodyProfile> load(String userId) async {
    final snapshot = await _doc(userId).get();
    return BodyProfile.fromMap(snapshot.data());
  }

  /// Replaces the saved profile, so cleared values are removed too.
  Future<void> save(String userId, BodyProfile profile) {
    return _doc(
      userId,
    ).set({...profile.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// The signed-in user's profile for features that only use it when it
  /// exists (makeovers, try-on, size hints). Empty when signed out or when
  /// it cannot be read, so those features still work without it.
  Future<BodyProfile> loadForCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const BodyProfile();
    try {
      return await load(userId);
    } on FirebaseException catch (error) {
      debugPrint('Unable to load profile details: ${error.code}');
      return const BodyProfile();
    }
  }
}

/// A failure with a message fit to show the user.
class BodyProfileException implements Exception {
  const BodyProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What the profile details page needs to load, save and upload. Injected
/// so the page can be tested without Firebase.
abstract interface class BodyProfileStore {
  Future<BodyProfile> load();
  Future<void> save(BodyProfile profile);

  /// Uploads a new [photo] and returns its URL.
  Future<String> uploadPhoto(BodyPhoto photo, Uint8List bytes);

  /// Deletes a photo that is no longer used. Best effort.
  Future<void> deletePhoto(String url);
}

/// [BodyProfileStore] for the signed-in user.
class FirebaseBodyProfileStore implements BodyProfileStore {
  FirebaseBodyProfileStore({
    BodyProfileService? service,
    StorageService? storage,
    FirebaseAuth? auth,
  }) : _service = service ?? BodyProfileService(),
       _storage = storage ?? StorageService(),
       _auth = auth ?? FirebaseAuth.instance;

  final BodyProfileService _service;
  final StorageService _storage;
  final FirebaseAuth _auth;

  String get _userId {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw const BodyProfileException(
        'Sign in to manage your profile details.',
      );
    }
    return userId;
  }

  @override
  Future<BodyProfile> load() => _service.load(_userId);

  @override
  Future<void> save(BodyProfile profile) => _service.save(_userId, profile);

  @override
  Future<String> uploadPhoto(BodyPhoto photo, Uint8List bytes) =>
      switch (photo) {
        BodyPhoto.face => _storage.uploadSelfieImageBytes(bytes, _userId),
        BodyPhoto.fullBody => _storage.uploadFullBodyImageBytes(bytes, _userId),
        BodyPhoto.hand => _storage.uploadHandImageBytes(bytes, _userId),
      };

  @override
  Future<void> deletePhoto(String url) async {
    try {
      await _storage.deleteImageByUrl(url);
    } on Exception catch (error) {
      // An orphaned file is harmless; the profile no longer points at it.
      debugPrint('Unable to delete old profile photo: $error');
    }
  }
}
