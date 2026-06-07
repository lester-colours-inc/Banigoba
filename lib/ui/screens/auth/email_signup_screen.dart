// Registers a new account and creates its initial Firestore user profile.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/auth_service.dart';

class EmailSignUpScreen extends StatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _authService = AuthService();
  bool _isLoading = false;
  bool _termsAccepted = false;
  String _stylePreference = 'casual';
  static const List<String> _styleTags = ['casual', 'afrochic', 'corporate', 'streetwear', 'glamour'];

  Future<void> _signUp() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept terms & policy')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (userCredential.user != null) {
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'displayName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'stylePreference': _stylePreference,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSocialSignIn(IconData icon, String provider) async {
    setState(() => _isLoading = true);
    try {
      if (provider == 'Google') {
        await _authService.signInWithGoogle();
      } else if (provider == 'Facebook') {
        await _authService.signInWithFacebook();
      } else if (provider == 'Apple') {
        await _authService.signInWithApple();
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing up with $provider: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Image.asset('assets/images/logo.png', height: 80),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Create your account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 25),
            _buildTextField(
              label: 'Name',
              hint: 'ex: jon smith',
              controller: _nameController,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Email',
              hint: 'ex: jon.smith@email.com',
              controller: _emailController,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Password',
              hint: '*********',
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Confirm password',
              hint: '*********',
              controller: _confirmPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 15),
            _buildStyleDropdown(),
            const SizedBox(height: 15),
            Row(
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v!),
                  activeColor: const Color(0xFF0D0140),
                ),
                const Expanded(
                  child: Text(
                    'I understood the terms & policy.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0140),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SIGN UP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 25),
            const Text('or sign up with', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(Icons.g_mobiledata, Colors.red, 'Google'),
                const SizedBox(width: 20),
                _buildSocialIcon(Icons.facebook, Colors.blue, 'Facebook'),
                const SizedBox(width: 20),
                _buildSocialIcon(Icons.apple, Colors.black, 'Apple'),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('SIGN IN', style: TextStyle(color: Color(0xFF0D0140), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade300),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String provider) {
    return GestureDetector(
      onTap: () => _handleSocialSignIn(icon, provider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildStyleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _stylePreference,
      items: _styleTags.map((style) {
        return DropdownMenuItem(
          value: style,
          child: Text(style[0].toUpperCase() + style.substring(1)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _stylePreference = value ?? 'casual'),
      decoration: InputDecoration(
        labelText: 'Style preference',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
