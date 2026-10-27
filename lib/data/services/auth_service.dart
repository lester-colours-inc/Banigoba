// Centralizes email, Google, Facebook, Apple, and sign-out authentication.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'permissions_service.dart';

import 'account_privacy_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Web Client ID for the appdemo-b9e3e Firebase project.
  static const String _webClientId =
      '379405824371-i657b4cj9ahacjl3j2u1v3df6erfm5a2.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
  );

  /// Sign in with a standard email and password account.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Registers an email/password user and stores the initial app profile.
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) return;

    await user.updateDisplayName(name);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': name,
      'stylePreference': 'casual',
      'role': 'user',
      'permissionStatus': PermissionsService.emptyPermissionsSummary,
      'permissionsGranted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Private, never on the public profile (U-5). Sign-in moves it again if
    // this fails, so it must never fail the sign-up itself.
    try {
      await AccountPrivacyService().secureEmail(userId: user.uid, email: email);
    } on FirebaseException catch (error) {
      debugPrint('Unable to secure email at sign-up: ${error.code}');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On Web, use the Firebase Auth popup flow directly.
        // This is more reliable than the google_sign_in plugin on web.
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // On Mobile, use the google_sign_in plugin flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Facebook (Placeholder - requires flutter_facebook_auth)
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        debugPrint('Facebook login failed: ${result.status}');
        debugPrint('Message: ${result.message}');
        return null;
      }

      final accessToken = result.accessToken!;

      final credential = FacebookAuthProvider.credential(accessToken.token);

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      rethrow;
    }
  }

  /// Signs in with Apple through Firebase's native provider flow.
  Future<UserCredential?> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      if (kIsWeb) {
        return await _auth.signInWithPopup(provider);
      }

      return await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'canceled' ||
          error.code == 'web-context-cancelled' ||
          error.code == 'popup-closed-by-user') {
        return null;
      }
      debugPrint('Apple Sign-In failed: ${error.code} ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Apple Sign-In error: $error');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
