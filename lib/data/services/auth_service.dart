// Centralizes email, Google, Facebook, Apple, and sign-out authentication on
// Supabase Auth. The profile row is created by a database trigger when the
// account is created, so sign-up only has to pass the name along.
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

class AuthService {
  SupabaseClient get _client => supabase;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kGoogleIosClientId.isEmpty ? null : kGoogleIosClientId,
    serverClientId: kGoogleWebClientId.isEmpty ? null : kGoogleWebClientId,
  );

  /// Sign in with a standard email and password account.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Registers an email/password user. The database creates the profile and
  /// the private email record from the account itself.
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  /// Sign in with Google. Returns false when the person backs out.
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      }
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException('Google did not return an ID token.');
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Facebook through Supabase's OAuth flow.
  Future<bool> signInWithFacebook() async {
    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? Uri.base.origin : _mobileRedirect,
        scopes: 'email,public_profile',
      );
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple through Supabase's OAuth flow.
  Future<bool> signInWithApple() async {
    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? Uri.base.origin : _mobileRedirect,
      );
    } catch (error) {
      debugPrint('Apple Sign-In error: $error');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } on Exception catch (error) {
      debugPrint('Google sign-out skipped: $error');
    }
    await _client.auth.signOut();
  }

  static const String _mobileRedirect =
      'com.coloursinc.banigoba://login-callback';
}
