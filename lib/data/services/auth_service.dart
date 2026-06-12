// Centralizes email, Google, Facebook, Apple, and sign-out authentication.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For Web: Replace with your actual Web Client ID from Firebase Console -> Authentication -> Sign-in method -> Google
  static const String _webClientId =
      '1057057002281-YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
  );

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
