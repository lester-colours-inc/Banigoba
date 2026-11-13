// A small on-device JSON cache, so the app can start and show what it last
// saw (profile, feed) when there is no internet connection.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthException,
        AuthRetryableFetchException,
        PostgrestException,
        StorageException;

/// How long a startup network call may take before the app carries on with
/// what it has saved.
const Duration kOfflineTimeout = Duration(seconds: 6);

/// True when [error] means "could not reach the server" rather than "the
/// server said no". Server answers (permission, bad request) are not offline.
bool isNetworkError(Object error) {
  if (error is TimeoutException) return true;
  // A refresh that could not reach the server.
  if (error is AuthRetryableFetchException) return true;
  if (error is PostgrestException ||
      error is AuthException ||
      error is StorageException) {
    return false;
  }
  // SocketException, http ClientException, HandshakeException and the
  // realtime channel errors all land here without importing dart:io (web).
  return error is Exception;
}

class LocalCache {
  LocalCache._();

  static const String _prefix = 'offline_cache.';

  /// The saved value for [key], or null if nothing (readable) was saved.
  static Future<Object?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      return raw == null ? null : jsonDecode(raw);
    } on FormatException catch (error) {
      debugPrint('Discarding unreadable cache "$key": $error');
      return null;
    }
  }

  /// Saves [value] (anything jsonEncode accepts) under [key]. Best effort:
  /// a failed save is logged and ignored.
  static Future<void> write(String key, Object? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode(value));
    } on Exception catch (error) {
      debugPrint('Unable to save cache "$key": $error');
    } on JsonUnsupportedObjectError catch (error) {
      debugPrint('Cache "$key" is not JSON: $error');
    }
  }

  static Future<Map<String, dynamic>?> readMap(String key) async {
    final value = await read(key);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<List<Map<String, dynamic>>?> readRows(String key) async {
    final value = await read(key);
    if (value is! List) return null;
    return [
      for (final row in value)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  /// Forgets everything saved (on sign-out, so the next person never sees
  /// the last person's feed).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    await Future.wait(keys.map(prefs.remove));
  }
}
