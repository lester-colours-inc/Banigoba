// Claims and changes @usernames. Uniqueness is enforced by the database (a
// unique index on the lower-cased name), so two people can never hold the
// same name; reserved names are refused by a trigger as well.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/onboarding/models/username.dart';

/// The name is taken or not allowed; [message] says why, in plain words.
class UsernameUnavailableException implements Exception {
  const UsernameUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UsernameService {
  UsernameService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? supabase;

  Future<bool> isAvailable(String input) async {
    final name = normalizeUsername(input);
    if (usernameProblem(name) != null) return false;
    final taken = await _db
        .from('profiles')
        .select('id')
        .eq('username', name)
        .limit(1);
    return taken.isEmpty;
  }

  /// The first free suggestion for [displayName], or null if all are taken.
  Future<String?> firstAvailableSuggestion(String displayName) async {
    for (final candidate in usernameSuggestions(displayName)) {
      if (await isAvailable(candidate)) return candidate;
    }
    return null;
  }

  /// Gives [userId] the username [input], releasing their old one.
  /// Throws [UsernameUnavailableException] when it is invalid or taken.
  Future<String> claim({required String userId, required String input}) async {
    final name = normalizeUsername(input);
    if (usernameProblem(name) case final problem?) {
      throw UsernameUnavailableException(problem);
    }
    try {
      await _db.from('profiles').update({'username': name}).eq('id', userId);
    } on PostgrestException catch (error) {
      // 23505: unique violation. 23514: check/reserved-name violation.
      if (error.code == '23505') {
        throw const UsernameUnavailableException(
          'That username is taken. Try another.',
        );
      }
      if (error.code == '23514') {
        throw const UsernameUnavailableException(
          'That username is reserved. Try another.',
        );
      }
      rethrow;
    }
    return name;
  }
}
