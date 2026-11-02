// Stores gallery-suggestion consent (E-5) in `gallery_consent`, which only
// the person can read or write.
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/gallery_consent.dart';

/// What the screens need; the real one reads the database, tests use a fake.
abstract interface class GalleryConsentStore {
  Future<GalleryConsent> load();
  Future<void> grant();
  Future<void> withdraw();
}

class GalleryConsentService implements GalleryConsentStore {
  String? get _uid => AppAuth.instance.currentUser?.uid;

  @override
  Future<GalleryConsent> load() async {
    final uid = _uid;
    if (uid == null) return const GalleryConsent.none();
    try {
      final row = await supabase
          .from('gallery_consent')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return GalleryConsent.fromMap(row);
    } on PostgrestException {
      return const GalleryConsent.none();
    }
  }

  Future<void> _save(GalleryConsent consent) async {
    final uid = _uid;
    if (uid == null) return;
    await supabase.from('gallery_consent').upsert({
      'user_id': uid,
      ...consent.toMap(),
      'changed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> grant() => _save(GalleryConsent.granted());

  @override
  Future<void> withdraw() => _save(GalleryConsent.granted().withdrawn());
}
