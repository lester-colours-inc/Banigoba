// Centralizes email, Google, Facebook, Apple, and sign-out authentication on
// Supabase Auth. The profile row is created by a database trigger when the
// account is created, so sign-up only has to pass the name along.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';

/// Facebook sign-in is hidden on the sign-in and sign-up screens for now;
/// set this to true to show it again. Google and email are always on.
const bool kShowFacebookSignIn = false;

/// Sign in with Apple is offered on iPhone and iPad only, where it uses the
/// phone's own Apple sheet. App Store rules ask for it next to Google.
bool get showAppleSignIn =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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

  /// Sign in with Apple. On iPhone this is the phone's own Apple sheet; the
  /// ID token it returns signs in to Supabase. Returns false when the person
  /// backs out. Elsewhere it falls back to Supabase's web flow.
  Future<bool> signInWithApple() async {
    if (showAppleSignIn) return _signInWithAppleNative();
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

  Future<bool> _signInWithAppleNative() async {
    final rawNonce = _randomNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return false;
      rethrow;
    }
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple did not return an ID token.');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    // Apple shares the name only the first time someone signs in.
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    if (name.isNotEmpty) {
      try {
        await _client.auth.updateUser(
          UserAttributes(data: {'full_name': name}),
        );
      } on AuthException catch (error) {
        debugPrint('Unable to save the Apple name: ${error.message}');
      }
    }
    return true;
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Changes the password after checking the current one.
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
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
