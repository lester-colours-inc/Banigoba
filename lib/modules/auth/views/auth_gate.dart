// The app's first screen: routes a person to onboarding, sign-in, Terms, a
// username, the first-run guide or Home. State lives in [AuthGateController].
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/admin/bindings/curators_workspace_binding.dart';
import 'package:banigoba/modules/admin/controllers/curators_workspace_controller.dart';
import 'package:banigoba/modules/admin/views/curators_workspace_page.dart';
import 'package:banigoba/modules/auth/controllers/auth_gate_controller.dart';
import 'package:banigoba/modules/auth/views/custom_login_screen.dart';
import 'package:banigoba/modules/home/views/main_screen.dart';
import 'package:banigoba/modules/onboarding/services/style_preferences_service.dart';
import 'package:banigoba/modules/onboarding/services/username_service.dart';
import 'package:banigoba/modules/onboarding/views/first_run_guide_screen.dart';
import 'package:banigoba/modules/onboarding/views/guide_actions.dart';
import 'package:banigoba/modules/onboarding/views/onboarding_screen.dart';
import 'package:banigoba/modules/onboarding/views/terms_screen.dart';
import 'package:banigoba/modules/onboarding/views/username_screen.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/views/provider_home_page.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/brand_splash.dart';
import 'package:banigoba/shared/widgets/offline_retry_screen.dart';

class AuthGate extends GetView<AuthGateController> {
  const AuthGate({super.key});

  /// [screen], or the brand splash while it is still being held.
  Widget _afterSplash(Widget screen) =>
      Obx(() => controller.holdingSplash.value ? const BrandSplash() : screen);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final done = controller.onboardingDone.value;
      if (done == null) return const BrandSplash();
      if (!done) return _afterSplash(const OnboardingScreen());
      return _signedInOrOut();
    });
  }

  Widget _signedInOrOut() {
    return StreamBuilder<AppUser?>(
      stream: AppAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandSplash();
        }
        final user = snapshot.data;
        if (user == null) {
          controller.noteSignedOut();
          return _afterSplash(const CustomLoginScreen());
        }
        controller.noteSignedIn(user);
        return FutureBuilder<void>(
          future: controller.profileCheckFor(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const BrandSplash();
            }
            return _profileStream(user);
          },
        );
      },
    );
  }

  Widget _profileStream(AppUser user) {
    // Re-subscribes (a new stream) each time "Try again" is tapped.
    return Obx(() {
      controller.profileRetry.value;
      return _profileStreamOnce(user);
    });
  }

  Widget _profileStreamOnce(AppUser user) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().watch(user.uid),
      builder: (context, userSnapshot) {
        // Only reached with nothing saved on this phone yet.
        if (userSnapshot.hasError && !userSnapshot.hasData) {
          return _afterSplash(
            OfflineRetryScreen(onRetry: controller.retryProfile),
          );
        }
        if (!userSnapshot.hasData) return const BrandSplash();
        final userData = userSnapshot.data ?? const <String, dynamic>{};
        final isAdmin =
            userData['isAdmin'] == true || userData['role'] == 'admin';
        if (isAdmin) {
          // Built inline rather than via its route, so register its binding.
          if (!Get.isRegistered<CuratorsWorkspaceController>()) {
            CuratorsWorkspaceBinding().dependencies();
          }
          return _afterSplash(const CuratorsWorkspacePage());
        }
        if (isProviderMode(userData)) {
          return _afterSplash(const ProviderHomePage());
        }
        // Everyone agrees to the Terms once per version (App Store 1.2)
        // before seeing anyone else's looks.
        return _withTerms(user, () => _afterTerms(user, userData));
      },
    );
  }

  /// [next] once [user] has agreed to the Terms; until then the Terms screen
  /// (or the splash while checking).
  Widget _withTerms(AppUser user, Widget Function() next) {
    return Obx(() {
      controller.termsRevision.value; // re-read the cached check on accept
      return FutureBuilder<bool>(
        future: controller.termsCheckFor(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const BrandSplash();
          }
          if (snapshot.data == true) return next();
          return _afterSplash(
            TermsScreen(
              onAccept: () => controller.acceptTerms(user),
              onDecline: controller.declineTerms,
            ),
          );
        },
      );
    });
  }

  /// After the Terms: @username, the first-run guide, then Home.
  Widget _afterTerms(AppUser user, Map<String, dynamic> userData) {
    // Everyone needs a unique @username (U-4). New and existing users get one
    // suggested from their name to confirm.
    if ((userData['username'] ?? '').toString().isEmpty) {
      final usernames = UsernameService();
      final name = (userData['displayName'] ?? '').toString();
      return _afterSplash(
        UsernameScreen(
          suggest: () => usernames.firstAvailableSuggestion(name),
          isAvailable: usernames.isAvailable,
          onClaim: (username) =>
              usernames.claim(userId: user.uid, input: username),
        ),
      );
    }
    // Asked once, after the account exists; the profile stream rebuilds into
    // Home as soon as it is answered or skipped.
    if (StylePreferencesService.needsPrompt(userData)) {
      return _afterSplash(
        FirstRunGuideScreen(
          userId: user.uid,
          name: (userData['displayName'] ?? '').toString(),
          actions: AppGuideActions(userId: user.uid),
        ),
      );
    }
    return _afterSplash(const MainScreen());
  }
}
