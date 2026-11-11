// Keeps the app's existing auth entry point while showing the email login UI.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/auth/views/email_signin_screen.dart';

class CustomLoginScreen extends StatelessWidget {
  const CustomLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmailSignInScreen();
  }
}
