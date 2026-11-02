// Loads and saves a user's personal profile details (BodyProfile).
//
// Stored in `body_profiles` (one private row per user, readable by its owner
// only), so measurements and body photos never sit on the public profile. The
// photos live under user-images/{uid}/, with unguessable names.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/body_profile.dart';
import 'storage_service.dart';

class BodyProfileService {
  Future<BodyProfile> load(String userId) async {
    final row = await supabase
        .from('body_profiles')
        .select('data')
        .eq('user_id', userId)
        .maybeSingle();
    final data = row?['data'];
    return BodyProfile.fromMap(
      data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }

  /// Replaces the saved profile, so cleared values are removed too.
  Future<void> save(String userId, BodyProfile profile) async {
    await supabase.from('body_profiles').upsert({
      'user_id': userId,
      'data': profile.toMap(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// The signed-in user's profile for features that only use it when it
  /// exists (makeovers, try-on, size hints). Empty when signed out or when
  /// it cannot be read, so those features still work without it.
  Future<BodyProfile> loadForCurrentUser() async {
    final userId = AppAuth.instance.currentUser?.uid;
    if (userId == null) return const BodyProfile();
    try {
      return await load(userId);
    } on PostgrestException catch (error) {
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
/// so the page can be tested without a backend.
abstract interface class BodyProfileStore {
  Future<BodyProfile> load();
  Future<void> save(BodyProfile profile);

  /// Uploads a new [photo] and returns its URL.
  Future<String> uploadPhoto(BodyPhoto photo, Uint8List bytes);

  /// Deletes a photo that is no longer used. Best effort.
  Future<void> deletePhoto(String url);
}

/// [BodyProfileStore] for the signed-in user.
class SupabaseBodyProfileStore implements BodyProfileStore {
  SupabaseBodyProfileStore({
    BodyProfileService? service,
    StorageService? storage,
  }) : _service = service ?? BodyProfileService(),
       _storage = storage ?? StorageService();

  final BodyProfileService _service;
  final StorageService _storage;

  String get _userId {
    final userId = AppAuth.instance.currentUser?.uid;
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
