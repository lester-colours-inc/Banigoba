import 'package:flutter/material.dart';
import 'auth/email_signin_screen.dart';
import '../../data/services/auth_service.dart';

class CustomLoginScreen extends StatelessWidget {
  const CustomLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'WELCOME,\nBANIGOBA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const Spacer(flex: 1),
              _buildSocialButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                onPressed: () => _handleSocialSignIn(context, authService, 'Apple'),
              ),
              const SizedBox(height: 15),
              _buildSocialButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onPressed: () => _handleSocialSignIn(context, authService, 'Google'),
              ),
              const SizedBox(height: 15),
              _buildSocialButton(
                icon: Icons.facebook,
                label: 'Continue with Facebook',
                onPressed: () => _handleSocialSignIn(context, authService, 'Facebook'),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 25),
              _buildSocialButton(
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailSignInScreen(),
                    ),
                  );
                },
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSocialSignIn(BuildContext context, AuthService authService, String provider) async {
    try {
      if (provider == 'Google') {
        await authService.signInWithGoogle();
      } else if (provider == 'Facebook') {
        await authService.signInWithFacebook();
      } else if (provider == 'Apple') {
        await authService.signInWithApple();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in with $provider: $e')),
        );
      }
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFEBE8),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
