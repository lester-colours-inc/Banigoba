// Lets the signed-in user manage account details, profile photo, and address.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;
import '../../../core/supabase/app_auth.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/private_account_service.dart';
import '../../../data/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/feed_ranking.dart';
import '../../../data/services/area_service.dart';
import '../../../data/services/gallery_consent_service.dart';
import '../../../data/models/provider_roles.dart';
import '../../../data/services/provider_service.dart';
import '../../../data/services/storage_service.dart';
import '../../widgets/consent_sheet.dart';
import '../../widgets/gallery_consent_sheet.dart';
import '../provider/become_provider_page.dart';
import '../../../data/services/style_preferences_service.dart';
import '../onboarding/style_preferences_screen.dart';
import '../../widgets/profile_photo_changer.dart';
import '../../../data/services/username_service.dart';
import '../onboarding/username_screen.dart';
import 'privacy_safety_section.dart';

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
  List<ProviderRole> _providerRoles = const [];
  bool _notifyTrending = true;
  final GalleryConsentService _galleryConsent = GalleryConsentService();
  bool _gallerySuggestions = false;
  final AreaService _area = AreaService();
  bool _useLocation = false;
  String _profileImageUrl = '';
  String _username = '';

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

  Future<void> _openStylePreferences() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final Map<String, dynamic> userData;
    try {
      userData = await ProfileService().get(user.uid);
    } on PostgrestException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to load preferences: ${error.message}')),
      );
      return;
    }

    final service = StylePreferencesService();
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (routeContext) => StylePreferencesScreen(
          isFirstRun: false,
          initial: StylePreferencesService.fromUserData(userData),
          onSave: (answers) async {
            await service.save(user.uid, answers);
            if (routeContext.mounted) Navigator.pop(routeContext);
          },
          onSkip: () async => Navigator.pop(routeContext),
        ),
      ),
    );
  }

  Future<void> _load() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final data = await ProfileService().get(user.uid);
    final address = await PrivateAccountService().address(user.uid);
    if (!mounted) return;
    _nameController.text = (data['displayName'] ?? user.displayName ?? '')
        .toString();
    _profileImageUrl = (data['profileImageUrl'] ?? user.photoURL ?? '')
        .toString();
    _username = (data['username'] ?? '').toString();
    _streetController.text = (address['street'] ?? '').toString();
    _cityController.text = (data['city'] ?? address['city'] ?? '').toString();
    _stateController.text = (address['state'] ?? '').toString();
    _postalController.text = (address['postalCode'] ?? '').toString();
    _countryController.text = (address['country'] ?? '').toString();
    _providerRoles = providerRolesOf(data);
    _notifyTrending = data['notifyTrending'] != false;
    _area.load(user.uid).then((record) {
      if (mounted) setState(() => _useLocation = record?.enabled ?? false);
    });
    _galleryConsent.load().then((consent) {
      if (mounted) setState(() => _gallerySuggestions = consent.isActive);
    });
    setState(() => _loading = false);
  }

  /// "Near me" from the phone's location: turning on explains first, asks the
  /// phone, and keeps only a rough area; turning off deletes it.
  Future<void> _setUseLocation(bool on) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    if (!on) {
      await _area.disable(user.uid);
      if (mounted) setState(() => _useLocation = false);
      return;
    }
    final agreed = await showConsentSheet(
      context,
      title: 'Use my location for Near me',
      points: kLocationConsentText,
    );
    if (!agreed) return;
    final result = await _area.enable(user.uid);
    if (!mounted) return;
    setState(() => _useLocation = result == AreaResult.enabled);
    _showMessage(switch (result) {
      AreaResult.enabled => 'Near me now uses your phone\'s location.',
      AreaResult.serviceOff => 'Location is switched off on your phone.',
      AreaResult.denied => 'Banigoba was not allowed to use your location.',
      AreaResult.deniedForever =>
        'Location is blocked for Banigoba. Allow it in your phone settings.',
      AreaResult.failed => 'We could not find your location. Try again.',
    });
  }

  /// Gallery suggestions (E-5): turning on shows the consent first; turning
  /// off withdraws it at once.
  Future<void> _setGallerySuggestions(bool on) async {
    if (on && !await showGalleryConsentSheet(context)) return;
    try {
      if (on) {
        await _galleryConsent.grant();
      } else {
        await _galleryConsent.withdraw();
      }
      if (mounted) setState(() => _gallerySuggestions = on);
    } on Exception catch (error) {
      _showMessage('Unable to change this: $error');
    }
  }

  /// Trending-look pushes on or off (at most one a day).
  Future<void> _setNotifyTrending(bool on) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _notifyTrending = on);
    try {
      await ProfileService().update(user.uid, {'notifyTrending': on});
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _notifyTrending = !on);
      _showMessage('Unable to change this: ${error.message}');
    }
  }

  /// Opens provider mode, or the one-time sign-up when the user holds no
  /// provider role yet.
  Future<void> _openProviderMode() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || _saving) return;
    if (_providerRoles.isEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BecomeProviderPage(suggestedName: _nameController.text.trim()),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ProviderService().setMode(user.uid, provider: true);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (error) {
      _showMessage('Unable to open provider mode: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeUsername() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    final usernames = UsernameService();
    final name = _nameController.text;
    final updated = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => UsernameScreen(
          current: _username,
          isFirstRun: false,
          suggest: () => usernames.firstAvailableSuggestion(name),
          isAvailable: usernames.isAvailable,
          onClaim: (username) =>
              usernames.claim(userId: user.uid, input: username),
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _username = updated);
  }

  Future<void> _pickProfilePicture() async {
    setState(() => _saving = true);
    try {
      final url = await changeProfilePhoto(
        context,
        picker: _picker,
        storage: _storage,
      );
      if (url != null && mounted) setState(() => _profileImageUrl = url);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || _saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    setState(() => _saving = true);
    try {
      final existingAddress = await PrivateAccountService().address(user.uid);
      await Future.wait([
        ProfileService().update(user.uid, {
          'displayName': name,
          // The city alone is public, so people near you can find each
          // other (the rest of the address is for delivery).
          'city': _cityController.text.trim(),
          // How people in the same city are matched, spelling aside.
          'cityKey': normalizeCity(_cityController.text),
        }),
        // The address is private, for delivery only.
        PrivateAccountService().saveAddress(user.uid, {
          ...existingAddress,
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'postalCode': _postalController.text.trim(),
          'country': _countryController.text.trim(),
        }),
      ]);
      _showMessage('Account settings saved.');
    } catch (error) {
      _showMessage('Unable to save settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final user = AppAuth.instance.currentUser;
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
      await AuthService().changePassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _showMessage('Password updated.');
    } on AuthException catch (error) {
      _showMessage(error.message);
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
    final user = AppAuth.instance.currentUser;
    final hasPasswordProvider = user?.hasPassword ?? false;
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
                              : CachedNetworkImageProvider(_profileImageUrl),
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
                  // The unique @handle (U-4); changed on its own screen so
                  // availability can be checked as you type.
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      key: const ValueKey('settings_username'),
                      leading: const Icon(Icons.alternate_email),
                      title: Text(
                        _username.isEmpty ? 'Choose a username' : '@$_username',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('How people find and mention you'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _saving ? null : _changeUsername,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email (private)',
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
                      Expanded(
                        child: _field(
                          _cityController,
                          'City (public, for Near me)',
                        ),
                      ),
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
                    'Style',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      key: const ValueKey('settings_style_preferences'),
                      leading: const Icon(Icons.style_outlined),
                      title: const Text(
                        'Style preferences',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Styles you like and what a makeover should change.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _saving ? null : _openStylePreferences,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      key: const ValueKey('notify_trending'),
                      value: _notifyTrending,
                      onChanged: _setNotifyTrending,
                      secondary: const Icon(Icons.trending_up),
                      title: const Text(
                        'Trending looks near me',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'A look people in your city are talking about. At '
                        'most one a day, and only when a look has real '
                        'attention.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      key: const ValueKey('use_location_switch'),
                      value: _useLocation,
                      onChanged: _setUseLocation,
                      secondary: const Icon(Icons.my_location),
                      title: const Text(
                        'Use my location for Near me',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Only a rough area about 22 km wide is saved, never '
                        'your exact position.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Photos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      key: const ValueKey('gallery_suggestions'),
                      value: _gallerySuggestions,
                      onChanged: _setGallerySuggestions,
                      secondary: const Icon(Icons.photo_library_outlined),
                      title: const Text(
                        'Suggestions from my photos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Show my recent photos on the makeover screen. They '
                        'stay on my phone until I pick one.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Business',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      key: const ValueKey('provider_mode_tile'),
                      leading: const Icon(Icons.storefront_outlined),
                      title: const Text(
                        'Provider mode',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _providerRoles.isEmpty
                            ? 'Run a shop, design service or hair salon on '
                                  'Banigoba.'
                            : 'Switch to your business: '
                                  '${_providerRoles.map((r) => r.label).join(', ')}.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _saving ? null : _openProviderMode,
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
                  const PrivacySafetySection(),
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
