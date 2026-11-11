// The shared frame for sign-in and sign-up: centered column, logo, title.
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.logoGap = 48,
    this.titleGap = 28,
  });

  final String title;
  final List<Widget> children;

  /// Space between the logo and the title.
  final double logoGap;

  /// Space between the title and the first child.
  final double titleGap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', width: 150),
                  ),
                  SizedBox(height: logoGap),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  SizedBox(height: titleGap),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
