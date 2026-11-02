// Supabase project settings, supplied at build time with
// --dart-define-from-file=dart_defines.json (see dart_defines.example.json).
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// The Google web client ID, used for Google sign-in on web and as the
/// server client ID on mobile so Supabase can verify the ID token.
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
);
const String kGoogleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
);

bool get isSupabaseConfigured =>
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;

/// Starts Supabase once, before the first screen. Throws a clear error when
/// the build was made without dart_defines.json.
Future<void> initializeSupabase() async {
  if (!isSupabaseConfigured) {
    throw StateError(
      'Supabase is not configured. Run with '
      '--dart-define-from-file=dart_defines.json.',
    );
  }
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
    debug: kDebugMode,
  );
}

/// The shared client. Only valid after [initializeSupabase].
SupabaseClient get supabase => Supabase.instance.client;
