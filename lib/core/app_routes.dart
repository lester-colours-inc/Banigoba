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
import '../ui/screens/shop/admin_products_page.dart';
import '../ui/screens/wardrobe/plan_ahead_page.dart';
import '../ui/screens/wardrobe/measurement_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _lastUser;
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingDone = prefs.getBool('onboarding_done') ?? false;
    });
  }

  Future<bool> _hasRequestedPermissions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('permissions_requested_$userId') ?? false;
  }

  Future<void> _markPermissionsRequested(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_requested_$userId', true);
  }

  Future<void> _upsertUserProfile(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
      if (data == null || !data.containsKey('stylePreference')) 'stylePreference': 'casual',
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
          if (user != _lastUser) {
            _lastUser = user;
            _upsertUserProfile(user);
          }

          // Check if permissions have been requested for this user
          return FutureBuilder<bool>(
            future: _hasRequestedPermissions(user.uid),
            builder: (context, permSnapshot) {
              if (permSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final hasRequestedPermissions = permSnapshot.data ?? false;

              if (!hasRequestedPermissions) {
                return OnboardingScreen(
                  permissionsOnly: true,
                  onPermissionsComplete: () async {
                    await _markPermissionsRequested(user.uid);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              }

              // Check role to decide where to land
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    final bool isAdmin = userData['role'] == 'admin' || userData['isAdmin'] == true;

                    if (isAdmin) {
                      return const AdminProductsPage();
                    }
                  }

                  return const MainScreen();
                },
              );
            },
          );
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
