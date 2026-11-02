// Defines application routes and decides which screen a user sees during startup.
import 'dart:async';

import 'package:flutter/material.dart';
import '../ui/screens/main/main_screen.dart';
import '../ui/screens/main/notifications_page.dart';
import '../ui/screens/main/daily_dress_up_page.dart';
import '../ui/screens/wardrobe/wardrobe_page.dart';
import '../ui/screens/shop/cart_page.dart';
import '../ui/screens/shop/shared_stock_page.dart';
import '../ui/screens/main/search_page.dart';
import '../ui/screens/social/profile_page.dart';
import '../ui/screens/makeover/avatar_try_on_page.dart';
import '../ui/screens/makeover/create_makeover_page.dart';
import '../ui/screens/makeover/makeover_page.dart';
import '../ui/screens/auth/custom_login_screen.dart';
import '../ui/screens/onboarding/onboarding_screen.dart';
import '../ui/screens/onboarding/style_preferences_screen.dart';
import '../ui/screens/permissions/permissions_request_screen.dart';
import '../data/models/provider_roles.dart';
import '../data/models/shop_link.dart';
import '../ui/screens/provider/provider_home_page.dart';
import '../ui/screens/shop/shops_page.dart';
import '../ui/screens/agents/agents_page.dart';
import '../ui/screens/designers/fashion_designers_page.dart';
import '../ui/screens/wardrobe/plan_ahead_page.dart';
import '../ui/screens/wardrobe/measurement_page.dart';
import '../ui/screens/admin/curators_workspace_page.dart';
import '../ui/screens/profile_details/body_profile_page.dart';
import '../ui/screens/settings/settings_page.dart';
import '../ui/widgets/brand_splash.dart';
import '../data/services/permissions_service.dart';
import '../data/services/style_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/profile_service.dart';
import 'supabase/app_auth.dart';
import '../data/services/username_service.dart';
import '../ui/screens/onboarding/username_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AppUser? _lastUser;
  bool? _onboardingDone;
  final Set<String> _permissionPromptHandledThisSession = {};
  final Map<String, Future<_PermissionGateState>> _permissionChecks = {};

  // The splash stays up until the sonic logo's reveal has played, while
  // onboarding, auth and permission checks carry on underneath it.
  late bool _holdingSplash;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    final splashRemaining = brandSplashTimeRemaining();
    _holdingSplash = splashRemaining > Duration.zero;
    if (_holdingSplash) {
      _splashTimer = Timer(splashRemaining, () {
        if (mounted) setState(() => _holdingSplash = false);
      });
    }
    _checkOnboarding();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  /// [screen], or the brand splash while it is still being held.
  Widget _afterSplash(Widget screen) =>
      _holdingSplash ? const BrandSplash() : screen;

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _onboardingDone = prefs.getBool(OnboardingScreen.doneKey) ?? false;
    });
  }

  /// The profile row is created with the account; here it is only topped up
  /// with a name if sign-in provided none, and stamped with "last seen". A
  /// failure must never block signing in.
  Future<void> _upsertUserProfile(AppUser user) async {
    try {
      final profiles = ProfileService();
      final data = await profiles.get(user.uid);
      final name = (data['displayName'] ?? '').toString();
      await profiles.update(user.uid, {
        if (name.isEmpty)
          'displayName':
              user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        'lastSeen': DateTime.now().toUtc().toIso8601String(),
      });
    } on Exception catch (error) {
      debugPrint('Unable to update profile on sign-in: $error');
    }
  }

  /// Which permissions the device still lacks. Read from the device itself;
  /// nothing about them is stored on the server.
  Future<_PermissionGateState> _checkUserPermissions(AppUser user) async {
    await _upsertUserProfile(user);
    final deviceStatuses = await PermissionsService.getPermissionsSummary();
    return _PermissionGateState(
      missingPermissions: deviceStatuses.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toSet(),
    );
  }

  Future<void> _completePermissionPrompt(
    AppUser user,
    Map<String, bool> statuses,
  ) async {
    if (!mounted) return;

    setState(() {
      _permissionPromptHandledThisSession.add(user.uid);
      _permissionChecks.remove(user.uid);
    });
  }

  Future<_PermissionGateState> _permissionCheckFor(AppUser user) {
    return _permissionChecks.putIfAbsent(
      user.uid,
      () => _checkUserPermissions(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const BrandSplash();
    }

    if (!_onboardingDone!) {
      return _afterSplash(const OnboardingScreen());
    }

    return StreamBuilder<AppUser?>(
      stream: AppAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandSplash();
        }

        final user = snapshot.data;

        if (user != null) {
          if (user.uid != _lastUser?.uid) {
            _lastUser = user;
          }

          return FutureBuilder<_PermissionGateState>(
            future: _permissionCheckFor(user),
            builder: (context, permissionSnapshot) {
              if (permissionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const BrandSplash();
              }

              if (permissionSnapshot.hasError) {
                return _afterSplash(
                  Scaffold(
                    body: Center(
                      child: Text(
                        'Unable to check app permissions: ${permissionSnapshot.error}',
                      ),
                    ),
                  ),
                );
              }

              final gateState = permissionSnapshot.data;
              final promptHandled = _permissionPromptHandledThisSession
                  .contains(user.uid);

              if (gateState?.missingPermissions.isNotEmpty == true &&
                  !promptHandled) {
                return _afterSplash(
                  PermissionsRequestScreen(
                    requiredPermissions: gateState!.missingPermissions,
                    onPermissionsComplete: (statuses) =>
                        _completePermissionPrompt(user, statuses),
                  ),
                );
              }

              return StreamBuilder<Map<String, dynamic>>(
                stream: ProfileService().watch(user.uid),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const BrandSplash();
                  }
                  final userData =
                      userSnapshot.data ?? const <String, dynamic>{};
                  final isAdmin =
                      userData['isAdmin'] == true ||
                      userData['role'] == 'admin';
                  if (isAdmin) {
                    return _afterSplash(const CuratorsWorkspacePage());
                  }
                  if (isProviderMode(userData)) {
                    return _afterSplash(const ProviderHomePage());
                  }
                  // Everyone needs a unique @username (U-4). New and existing
                  // users get one suggested from their name to confirm.
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
                  // Asked once, after the account exists; the user document
                  // stream rebuilds into Home as soon as it is answered or
                  // skipped.
                  if (StylePreferencesService.needsPrompt(userData)) {
                    final preferences = StylePreferencesService();
                    return _afterSplash(
                      StylePreferencesScreen(
                        onSave: (answers) =>
                            preferences.save(user.uid, answers),
                        onSkip: () => preferences.skip(user.uid),
                      ),
                    );
                  }
                  return _afterSplash(const MainScreen());
                },
              );
            },
          );
        }

        if (_lastUser != null) {
          _permissionChecks.remove(_lastUser!.uid);
          _permissionPromptHandledThisSession.remove(_lastUser!.uid);
          _lastUser = null;
        }

        return _afterSplash(const CustomLoginScreen());
      },
    );
  }
}

class AppRoutes {
  static const String root = '/';
  static const String home = '/home';
  static const String wardrobe = '/wardrobe';
  static const String cart = '/cart';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String avatarTryOn = '/avatar-try-on';
  static const String planAhead = '/plan-ahead';
  static const String measurement = '/measurement';
  static const String curatorsWorkspace = '/admin/curators-workspace';
  static const String settings = '/settings';
  static const String shops = '/shops';
  static const String fashionDesigners = '/fashion-designers';
  static const String agents = '/agents';
  static const String notifications = '/notifications';

  // Photos, sizes and measurements for the eFitting Room and Fashion Idol
  // Twin.
  static const String bodyProfile = '/profile/details';

  // A makeover is started from Home's floating Makeover button, not a tab.
  static const String makeover = '/makeover';

  // The earlier catalogue-first makeover. Not linked from anywhere now; kept
  // for "Get this look" (Phase 5), which needs real items to try on.
  static const String makeoverWithItems = '/makeover/items';

  // Daily Dress Up and Hair Style are not tab destinations — their work is one
  // coordinated makeover journey. They stay routable because they also host
  // the shop try-on picker and the hairstyle catalogue.
  static const String dailyDressUp = '/daily-dress-up';

  /// Routes that carry data, such as a shared stock link
  /// ("/s?id=…", K-9), opened from the web, a QR code or a phone link.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    final linkId = uri == null ? null : shopLinkIdFrom(uri);
    if (linkId == null) return null;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => SharedStockPage(linkId: linkId),
    );
  }

  static Map<String, WidgetBuilder> routes = {
    root: (context) => const AuthGate(),
    home: (context) => const MainScreen(),
    wardrobe: (context) => const WardrobePage(),
    cart: (context) => const CartPage(),
    search: (context) => const SearchPage(),
    profile: (context) => const ProfilePage(),
    avatarTryOn: (context) => const AvatarTryOnPage(),
    planAhead: (context) => const PlanAheadPage(),
    measurement: (context) => const MeasurementPage(),
    curatorsWorkspace: (context) => const CuratorsWorkspacePage(),
    settings: (context) => const SettingsPage(),
    shops: (context) => const ShopsPage(),
    fashionDesigners: (context) => const FashionDesignersPage(),
    agents: (context) => const AgentsPage(),
    notifications: (context) => const NotificationsPage(),
    bodyProfile: (context) => const BodyProfilePage(),
    makeover: (context) => const MakeoverPage(),
    makeoverWithItems: (context) => const CreateMakeoverPage(),
    dailyDressUp: (context) => const DailyDressUpPage(),
  };
}

class _PermissionGateState {
  final Set<String> missingPermissions;

  const _PermissionGateState({required this.missingPermissions});
}
