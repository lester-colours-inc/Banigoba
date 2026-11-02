// The signed-in user, as the rest of the app sees them. Wraps Supabase Auth
// behind the few fields the screens use (uid, email, name, photo) so call
// sites do not depend on the auth provider.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.providers = const [],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  /// How the account signs in, e.g. `email`, `google`, `facebook`.
  final List<String> providers;

  /// Whether the account has a password to change.
  bool get hasPassword => providers.contains('email');

  factory AppUser.fromSupabase(User user) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    String? text(Object? value) {
      final s = value?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return AppUser(
      uid: user.id,
      email: user.email,
      displayName: text(meta['full_name'] ?? meta['name']),
      photoURL: text(meta['avatar_url'] ?? meta['picture']),
      providers: [
        if (user.appMetadata['providers'] case final List list)
          for (final provider in list) provider.toString(),
      ],
    );
  }
}

class AppAuth {
  AppAuth._();
  static final AppAuth instance = AppAuth._();

  /// Who is signed in right now, or null.
  AppUser? get currentUser {
    if (!isSupabaseConfigured) return null;
    final user = supabase.auth.currentUser;
    return user == null ? null : AppUser.fromSupabase(user);
  }

  /// Emits the signed-in user (or null) now and on every change.
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    yield* supabase.auth.onAuthStateChange.map((_) => currentUser);
  }
}
