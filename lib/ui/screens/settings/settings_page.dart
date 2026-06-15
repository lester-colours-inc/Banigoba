// Lets the signed-in user manage account details, profile photo, and address.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _primaryColor = Color(0xFF0D0140);
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _picker = ImagePicker();
  final _storage = StorageService();

  bool _loading = true;
  bool _saving = false;
  bool _sellerMode = false;
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final address = Map<String, dynamic>.from(
      data['address'] as Map? ?? const {},
    );
    if (!mounted) return;
    _nameController.text = (data['displayName'] ?? user.displayName ?? '')
        .toString();
    _profileImageUrl =
        (data['profileImageURL'] ??
                data['profileImageUrl'] ??
                user.photoURL ??
                '')
            .toString();
    _streetController.text = (address['street'] ?? '').toString();
    _cityController.text = (address['city'] ?? '').toString();
    _stateController.text = (address['state'] ?? '').toString();
    _postalController.text = (address['postalCode'] ?? '').toString();
    _countryController.text = (address['country'] ?? '').toString();
    _sellerMode = data['sellerMode'] == true;
    setState(() => _loading = false);
  }

  Future<void> _setSellerMode(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _saving) return;
    setState(() {
      _saving = true;
      _sellerMode = enabled;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'sellerMode': enabled,
        if (enabled) 'isSeller': true,
        'sellerModeUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _showMessage(
        enabled
            ? 'Seller Mode enabled. Opening your boutique dashboard.'
            : 'Seller Mode disabled.',
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) setState(() => _sellerMode = !enabled);
      _showMessage('Unable to change Seller Mode: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1000,
    );
    if (image == null) return;

    setState(() => _saving = true);
    try {
      final url = await _storage.uploadProfileImageBytes(
        await image.readAsBytes(),
        user.uid,
      );
      await Future.wait([
        user.updatePhotoURL(url),
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImageURL': url,
          'profileImageUrl': url,
          'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]);
      if (mounted) setState(() => _profileImageUrl = url);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    setState(() => _saving = true);
    try {
      await Future.wait([
        user.updateDisplayName(name),
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': name,
          'address': {
            'street': _streetController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'postalCode': _postalController.text.trim(),
            'country': _countryController.text.trim(),
          },
          'accountUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]);
      _showMessage('Account settings saved.');
    } catch (error) {
      _showMessage('Unable to save settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    if (currentPassword.isEmpty || newPassword.length < 6) {
      _showMessage(
        'Enter your current password and a new password of 6+ characters.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await user.updatePassword(newPassword);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _showMessage('Password updated.');
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Unable to update password.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPasswordProvider =
        user?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: _primaryColor,
                          backgroundImage: _profileImageUrl.isEmpty
                              ? null
                              : NetworkImage(_profileImageUrl),
                          child: _profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 54,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton.filled(
                            onPressed: _saving ? null : _pickProfilePicture,
                            icon: const Icon(Icons.camera_alt_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Address',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _field(_streetController, 'Street address'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_cityController, 'City')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_stateController, 'State')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_postalController, 'Postal code')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_countryController, 'Country')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Save Settings'),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Selling',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      value: _sellerMode,
                      onChanged: _saving ? null : _setSellerMode,
                      activeThumbColor: _primaryColor,
                      secondary: const Icon(Icons.storefront_outlined),
                      title: const Text(
                        'Seller Mode',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Switch to your boutique dashboard to manage your shop and products.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (hasPasswordProvider) ...[
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _saving ? null : _changePassword,
                      child: const Text('Update Password'),
                    ),
                  ] else
                    const Text(
                      'Password is managed by your social sign-in provider.',
                    ),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
