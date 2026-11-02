// Registers a new account; the database creates its profile.
import 'package:flutter/material.dart';

import '../../../data/services/auth_service.dart';

class EmailSignUpScreen extends StatefulWidget {
  EmailSignUpScreen({super.key, AuthService? authService})
    : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  static const _navy = Color(0xFF17008A);
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Complete all account details');
      return;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Enter a valid email address');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    if (!_termsAccepted) {
      _showMessage('Please accept terms & policy');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.registerWithEmail(
        name: _nameController.text.trim(),
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
      if (mounted) _showMessage('Error signing up with $provider: $error');
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
                  const SizedBox(height: 48),
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SignUpField(
                    label: 'Name',
                    hint: 'ex: jon smith',
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: 16),
                  _SignUpField(
                    label: 'Email',
                    hint: 'ex: jon.smith@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  _SignUpField(
                    label: 'Password',
                    hint: '*********',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: _passwordToggle(
                      obscure: _obscurePassword,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SignUpField(
                    label: 'Confirm password',
                    hint: '*********',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmation,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signUp(),
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: _passwordToggle(
                      obscure: _obscureConfirmation,
                      onPressed: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: _isLoading
                              ? null
                              : (value) => setState(
                                  () => _termsAccepted = value ?? false,
                                ),
                          activeColor: _navy,
                          side: const BorderSide(color: _navy),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I understood the ',
                            children: [
                              TextSpan(
                                text: 'terms & policy.',
                                style: TextStyle(color: _navy),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'or sign up with',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8B8B8B)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SignUpSocialButtons(
                    enabled: !_isLoading,
                    onPressed: _handleSocialSignIn,
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Have an account? ',
                        style: TextStyle(color: Color(0xFF777777)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _navy,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'SIGN IN',
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

  Widget _passwordToggle({
    required bool obscure,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscure ? 'Show password' : 'Hide password',
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
    );
  }
}

class _SignUpField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;

  const _SignUpField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Color(0xFF707070))),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Color(0xFFC7C7C7)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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

class _SignUpSocialButtons extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onPressed;

  const _SignUpSocialButtons({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SignUpSocialButton(
          label: 'G',
          tooltip: 'Google',
          color: const Color(0xFF4285F4),
          onPressed: enabled ? () => onPressed('Google') : null,
        ),
        const SizedBox(width: 14),
        _SignUpSocialButton(
          icon: Icons.facebook,
          tooltip: 'Facebook',
          color: const Color(0xFF1877F2),
          onPressed: enabled ? () => onPressed('Facebook') : null,
        ),
        const SizedBox(width: 14),
        _SignUpSocialButton(
          icon: Icons.apple,
          tooltip: 'Apple',
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: enabled ? () => onPressed('Apple') : null,
        ),
      ],
    );
  }
}

class _SignUpSocialButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const _SignUpSocialButton({
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
