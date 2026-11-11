// Handles email/password sign-in and navigation to account registration.
import 'package:flutter/material.dart';

import '../../../data/services/auth_service.dart';
import 'email_signup_screen.dart';

class EmailSignInScreen extends StatefulWidget {
  EmailSignInScreen({super.key, AuthService? authService})
    : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  static const _navy = Color(0xFF17008A);
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Enter your email and password');
      return;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialSignIn(String provider) async {
    setState(() => _isLoading = true);
    try {
      if (provider == 'Google') {
        await widget.authService.signInWithGoogle();
      } else if (provider == 'Facebook') {
        await widget.authService.signInWithFacebook();
      } else {
        await widget.authService.signInWithApple();
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) _showMessage('Error signing in with $provider: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

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
                  const SizedBox(height: 84),
                  const Text(
                    'Sign in your account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _AuthField(
                    label: 'Email',
                    hint: 'ex: jon.smith@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  _AuthField(
                    label: 'Password',
                    hint: '*********',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  _PrimaryAuthButton(
                    label: 'SIGN IN',
                    isLoading: _isLoading,
                    onPressed: _signIn,
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'or sign in with',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8B8B8B)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SocialButtons(
                    enabled: !_isLoading,
                    onPressed: _handleSocialSignIn,
                  ),
                  const SizedBox(height: 44),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Don’t have an account? ',
                        style: TextStyle(color: Color(0xFF777777)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => EmailSignUpScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _navy,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _AuthField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Color(0xFF707070))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: label == 'Email'
              ? const [AutofillHints.email]
              : const [AutofillHints.password],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Color(0xFFC7C7C7)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _EmailSignInScreenState._navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _EmailSignInScreenState._navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _SocialButtons extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onPressed;

  const _SocialButtons({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SocialButton(
          label: 'G',
          tooltip: 'Google',
          color: const Color(0xFF4285F4),
          onPressed: enabled ? () => onPressed('Google') : null,
        ),
        if (kShowFacebookSignIn) ...[
          const SizedBox(width: 14),
          _SocialButton(
            icon: Icons.facebook,
            tooltip: 'Facebook',
            color: const Color(0xFF1877F2),
            onPressed: enabled ? () => onPressed('Facebook') : null,
          ),
        ],
        if (showAppleSignIn) ...[
          const SizedBox(width: 14),
          _SocialButton(
            icon: Icons.apple,
            tooltip: 'Apple',
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: enabled ? () => onPressed('Apple') : null,
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const _SocialButton({
    this.icon,
    this.label,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          icon: icon != null
              ? Icon(icon, color: color, size: 27)
              : Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
