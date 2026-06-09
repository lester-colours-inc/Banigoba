// Defines application routes and decides which screen a user sees during startup.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ui/screens/main/main_screen.dart';
import '../ui/screens/wardrobe/wardrobe_page.dart';
import '../ui/screens/shop/cart_page.dart';
import '../ui/screens/main/search_page.dart';
import '../ui/screens/social/profile_page.dart';
import '../ui/screens/onboarding/camera_screen.dart';
import '../ui/screens/auth/custom_login_screen.dart';
import '../ui/screens/onboarding/onboarding_screen.dart';
import '../ui/screens/permissions/permissions_request_screen.dart';
import '../ui/screens/shop/admin_products_page.dart';
import '../ui/screens/wardrobe/plan_ahead_page.dart';
import '../ui/screens/wardrobe/measurement_page.dart';
import '../data/services/permissions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _lastUser;
  bool? _onboardingDone;
  final Set<String> _permissionPromptHandledThisSession = {};
  final Map<String, Future<_PermissionGateState>> _permissionChecks = {};

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _onboardingDone = prefs.getBool('onboarding_done') ?? false;
    });
  }

  Future<void> _upsertUserProfile(User user) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
      if (data == null || !data.containsKey('stylePreference'))
        'stylePreference': 'casual',
      if (data == null || !data.containsKey('permissionsGranted'))
        'permissionsGranted': false,
      if (data == null || !data.containsKey('permissionStatus'))
        'permissionStatus': PermissionsService.emptyPermissionsSummary,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<_PermissionGateState> _checkUserPermissions(User user) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final results = await Future.wait([
      userRef.get(),
      PermissionsService.getPermissionsSummary(),
    ]);

    final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final deviceStatuses = results[1] as Map<String, bool>;
    final userData = userSnapshot.data();
    final storedStatuses = Map<String, dynamic>.from(
      userData?['permissionStatus'] as Map? ?? const {},
    );
    final storedAsGranted = userData?['permissionsGranted'] == true;
    final devicePermissionsGranted =
        PermissionsService.areAllPermissionsGranted(deviceStatuses);
    final storedStatusesMatch = deviceStatuses.entries.every(
      (entry) => storedStatuses[entry.key] == entry.value,
    );

    if (!storedStatusesMatch || storedAsGranted != devicePermissionsGranted) {
      await _savePermissionStatuses(user.uid, deviceStatuses);
    }

    return _PermissionGateState(
      shouldRequestPermissions: !devicePermissionsGranted,
      isAdmin: userData?['role'] == 'admin' || userData?['isAdmin'] == true,
    );
  }

  Future<void> _savePermissionStatuses(
    String userId,
    Map<String, bool> statuses,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'permissionStatus': statuses,
      'permissionsGranted': PermissionsService.areAllPermissionsGranted(
        statuses,
      ),
      'permissionsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _completePermissionPrompt(
    User user,
    Map<String, bool> statuses,
  ) async {
    await _savePermissionStatuses(user.uid, statuses);
    if (!mounted) return;

    setState(() {
      _permissionPromptHandledThisSession.add(user.uid);
      _permissionChecks.remove(user.uid);
    });
  }

  Future<_PermissionGateState> _permissionCheckFor(User user) {
    return _permissionChecks.putIfAbsent(
      user.uid,
      () => _checkUserPermissions(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_onboardingDone!) {
      return const OnboardingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          if (user.uid != _lastUser?.uid) {
            _lastUser = user;
            _upsertUserProfile(user);
          }

          return FutureBuilder<_PermissionGateState>(
            future: _permissionCheckFor(user),
            builder: (context, permissionSnapshot) {
              if (permissionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (permissionSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Unable to check app permissions: ${permissionSnapshot.error}',
                    ),
                  ),
                );
              }

              final gateState = permissionSnapshot.data;
              final promptHandled = _permissionPromptHandledThisSession
                  .contains(user.uid);

              if (gateState?.shouldRequestPermissions == true &&
                  !promptHandled) {
                return PermissionsRequestScreen(
                  onPermissionsComplete: (statuses) =>
                      _completePermissionPrompt(user, statuses),
                );
              }

              return gateState?.isAdmin == true
                  ? const AdminProductsPage()
                  : const MainScreen();
            },
          );
        }

        if (_lastUser != null) {
          _permissionChecks.remove(_lastUser!.uid);
          _permissionPromptHandledThisSession.remove(_lastUser!.uid);
          _lastUser = null;
        }

        return const CustomLoginScreen();
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
  static const String camera = '/camera';
  static const String planAhead = '/plan-ahead';
  static const String measurement = '/measurement';

  static Map<String, WidgetBuilder> routes = {
    root: (context) => const AuthGate(),
    home: (context) => const MainScreen(),
    wardrobe: (context) => const WardrobePage(),
    cart: (context) => const CartPage(),
    search: (context) => const SearchPage(),
    profile: (context) => const ProfilePage(),
    camera: (context) => const CameraScreen(),
    planAhead: (context) => const PlanAheadPage(),
    measurement: (context) => const MeasurementPage(),
  };
}

class _PermissionGateState {
  final bool shouldRequestPermissions;
  final bool isAdmin;

  const _PermissionGateState({
    required this.shouldRequestPermissions,
    required this.isAdmin,
  });
}
