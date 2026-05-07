import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
//import '../screens/home_page.dart';
import '../screens/wardrobe_page.dart';
import '../screens/cart_page.dart';
import '../screens/search_page.dart';
import '../screens/profile_page.dart';
import '../screens/camera_screen.dart';
import '../screens/login_screen.dart';
import '../screens/admin_products_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _lastUser;

  @override
  Widget build(BuildContext context) {
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
            // Update user profile in background
            FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'displayName': user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
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
        }

        return const LoginScreen();
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

  static Map<String, WidgetBuilder> routes = {
    root: (context) => const AuthGate(),
    home: (context) => const MainScreen(),
    wardrobe: (context) => const WardrobePage(),
    cart: (context) => const CartPage(),
    search: (context) => const SearchPage(),
    profile: (context) => const ProfilePage(),
    camera: (context) => const CameraScreen(),
  };
}

