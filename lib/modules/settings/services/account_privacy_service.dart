// Keeps a user's email off their public profile (October 2026 review, U-5).
//
// profiles are readable by every signed-in user, so the email lives in the
// owner-only private_account table. People who already know someone's full
// address can still find them: sign-up registers a SHA-256 of the lower-cased
// email, and find_user_by_email_hash answers for an exact hash only, so
// emails cannot be harvested.
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';

/// The lookup key for [email]: SHA-256 of the trimmed, lower-cased address,
/// so the stored key does not reveal the address.
String emailLookupKey(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

/// Whether [text] looks like a whole email address, worth a lookup.
bool looksLikeEmail(String text) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim());

class AccountPrivacyService {
  /// The uid registered for exactly [email], or null.
  Future<String?> findUserByEmail(String email) async {
    if (!looksLikeEmail(email)) return null;
    final uid = await supabase.rpc(
      'find_user_by_email_hash',
      params: {'email_hash': emailLookupKey(email)},
    );
    return uid is String && uid.isNotEmpty ? uid : null;
  }
}
