// What the App Store asks of a social app with user content and AI (guidelines
// 1.2, 5.1.1 and 5.1.2): block people, report looks and profiles, agree to the
// Terms, consent before photos go to the AI services, and delete the account.
// The database enforces blocks and hides much-reported looks; see
// supabase/migrations/20261105000001_app_store_safety.sql.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/legal_links.dart';
import '../../core/supabase/supabase_config.dart';

/// Why someone reports a look or a profile.
enum ReportReason {
  harassment('Bullying or harassment'),
  hate('Hate speech or symbols'),
  nudity('Nudity or sexual content'),
  violence('Violence or threats'),
  spam('Spam or scam'),
  impersonation('Pretending to be someone else'),
  other('Something else');

  const ReportReason(this.label);
  final String label;
}

class SafetyService {
  SafetyService._();
  static final SafetyService instance = SafetyService._();

  /// People the signed-in person has blocked. Screens filter by it straight
  /// away; the database also hides them on the next load.
  final ValueNotifier<Set<String>> blockedIds = ValueNotifier(const {});

  String get _me {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in first.');
    return id;
  }

  // ── blocking ──────────────────────────────────────────────────────────────

  Future<void> loadBlocked() async {
    final rows = await supabase
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', _me);
    blockedIds.value = {for (final row in rows) row['blocked_id'].toString()};
  }

  bool isBlocked(String userId) => blockedIds.value.contains(userId);

  Future<void> block(String userId) async {
    await supabase.from('user_blocks').upsert({
      'blocker_id': _me,
      'blocked_id': userId,
    });
    blockedIds.value = {...blockedIds.value, userId};
  }

  Future<void> unblock(String userId) async {
    await supabase
        .from('user_blocks')
        .delete()
        .eq('blocker_id', _me)
        .eq('blocked_id', userId);
    blockedIds.value = {...blockedIds.value}..remove(userId);
  }

  // ── reports ───────────────────────────────────────────────────────────────

  Future<void> reportPost(String postId, ReportReason reason) => supabase
      .from('post_reports')
      .upsert({'post_id': postId, 'reporter_id': _me, 'reason': reason.name});

  Future<void> reportProfile(String userId, ReportReason reason) =>
      supabase.from('profile_reports').upsert({
        'profile_id': userId,
        'reporter_id': _me,
        'reason': reason.name,
      });

  // ── consent ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _consentRow() => supabase
      .from('private_account')
      .select('terms_accepted_at, terms_version, ai_photo_consent_at')
      .eq('id', _me)
      .maybeSingle();

  /// Whether the person has agreed to the current Terms.
  Future<bool> hasAcceptedTerms() async {
    final row = await _consentRow();
    return row?['terms_accepted_at'] != null &&
        row?['terms_version'] == kTermsVersion;
  }

  Future<void> acceptTerms() => supabase.from('private_account').upsert({
    'id': _me,
    'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
    'terms_version': kTermsVersion,
  });

  bool? _aiConsentCache;

  Future<bool> hasAiPhotoConsent() async {
    if (_aiConsentCache != null) return _aiConsentCache!;
    final row = await _consentRow();
    return _aiConsentCache = row?['ai_photo_consent_at'] != null;
  }

  Future<void> setAiPhotoConsent(bool allowed) async {
    await supabase.from('private_account').upsert({
      'id': _me,
      'ai_photo_consent_at': allowed
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    });
    _aiConsentCache = allowed;
  }

  // ── account deletion ──────────────────────────────────────────────────────

  /// Deletes the account, its data and its pictures, then signs out.
  Future<void> deleteAccount() async {
    try {
      await supabase.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error']?.toString() : null;
      throw Exception(message ?? 'Unable to delete your account right now.');
    }
    reset();
    await supabase.auth.signOut();
  }

  /// Forgets cached state when the person signs out.
  void reset() {
    blockedIds.value = const {};
    _aiConsentCache = null;
  }
}
