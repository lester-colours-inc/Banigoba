import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui;
import '../navigation/app_routes.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ui.SignInScreen(
      providers: [
        ui.EmailAuthProvider(),
      ],

      headerBuilder: (context, constraints, shrinkOffset) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.indigo,
          ),
        );
      },

      subtitleBuilder: (context, action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: action == ui.AuthAction.signIn
              ? const Text('Welcome back to Banigoba!')
              : const Text('Create an account to start.'),
        );
      },
    );
  }
}