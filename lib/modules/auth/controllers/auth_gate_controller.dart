// Decides what a person sees at launch: splash, onboarding, sign-in, Terms,
// username, the first-run guide, then Home. Owns the per-session checks.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:banigoba/core/legal_links.dart';
import 'package:banigoba/core/offline/local_cache.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/auth/services/auth_service.dart';
import 'package:banigoba/modules/onboarding/views/onboarding_screen.dart';
import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/brand_splash.dart';

class AuthGateController extends GetxController {
  /// Null until the saved onboarding flag has been read.
  final Rxn<bool> onboardingDone = Rxn<bool>();

  /// True while the sonic logo's reveal is still playing; the splash stays up
  /// until then while onboarding, auth and profile checks carry on beneath it.
  final RxBool holdingSplash = false.obs;

  /// Bumped when Terms are accepted so views re-read the cached check.
  final RxInt termsRevision = 0.obs;

  /// Bumped by "Try again" on the offline screen to reload the profile.
  final RxInt profileRetry = 0.obs;

  void retryProfile() => profileRetry.value++;

  AppUser? _lastUser;
  Timer? _splashTimer;

  // Each signed-in person's profile row, made or refreshed once per session.
  final Map<String, Future<void>> _profileChecks = {};
  // Whether each signed-in person has agreed to the current Terms (1.2).
  final Map<String, Future<bool>> _termsChecks = {};

  final ProfileService _profiles;
  final SafetyService _safety;

  AuthGateController({ProfileService? profiles, SafetyService? safety})
    : _profiles = profiles ?? ProfileService(),
      _safety = safety ?? SafetyService.instance;

  @override
  void onInit() {
    super.onInit();
    final remaining = brandSplashTimeRemaining();
    holdingSplash.value = remaining > Duration.zero;
    if (holdingSplash.value) {
      _splashTimer = Timer(remaining, () => holdingSplash.value = false);
    }
    _loadOnboardingFlag();
  }

  @override
  void onClose() {
    _splashTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingDone.value = prefs.getBool(OnboardingScreen.doneKey) ?? false;
  }

  /// The profile row is created with the account; here it is only topped up
  /// with a name if sign-in provided none, and stamped with "last seen". A
  /// failure must never block signing in.
  Future<void> _upsertUserProfile(AppUser user) async {
    try {
      final data = await _profiles.get(user.uid);
      final name = (data['displayName'] ?? '').toString();
      await _profiles.update(user.uid, {
        if (name.isEmpty)
          'displayName':
              user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        'lastSeen': DateTime.now().toUtc().toIso8601String(),
      });
    } on Exception catch (error) {
      debugPrint('Unable to update profile on sign-in: $error');
    }
  }

  // Device permissions are asked for where first needed, not here. Offline
  // (or on a slow connection) the app does not wait for it.
  Future<void> profileCheckFor(AppUser user) =>
      _profileChecks.putIfAbsent(user.uid, () {
        return _upsertUserProfile(user).timeout(
          kOfflineTimeout,
          onTimeout: () => debugPrint('Profile check still running; going on'),
        );
      });

  static String _termsCacheKey(String uid) => 'terms.$uid';

  Future<bool> termsCheckFor(AppUser user) {
    return _termsChecks.putIfAbsent(user.uid, () async {
      unawaited(
        _safety.loadBlocked().catchError(
          (Object error) => debugPrint('Unable to load blocked people: $error'),
        ),
      );
      try {
        final accepted = await _safety.hasAcceptedTerms().timeout(
          kOfflineTimeout,
        );
        if (accepted) await _rememberTerms(user);
        return accepted;
      } on Exception catch (error) {
        debugPrint('Unable to check Terms acceptance: $error');
        // Offline: trust this phone's record of agreeing to these Terms.
        // Otherwise asked again rather than locked out.
        return isNetworkError(error) &&
            await LocalCache.read(_termsCacheKey(user.uid)) == kTermsVersion;
      }
    });
  }

  Future<void> _rememberTerms(AppUser user) =>
      LocalCache.write(_termsCacheKey(user.uid), kTermsVersion);

  Future<void> acceptTerms(AppUser user) async {
    await _safety.acceptTerms();
    await _rememberTerms(user);
    _termsChecks[user.uid] = Future.value(true);
    termsRevision.value++;
  }

  Future<void> declineTerms() => AuthService().signOut();

  /// Remember who is signed in so a sign-out can clear their cached checks.
  void noteSignedIn(AppUser user) => _lastUser = user;

  void noteSignedOut() {
    final last = _lastUser;
    if (last == null) return;
    _termsChecks.remove(last.uid);
    _safety.reset();
    _profileChecks.remove(last.uid);
    _lastUser = null;
  }
}
