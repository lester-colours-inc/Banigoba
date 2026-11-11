// Settings: the account details, address and preferences, loaded once and
// saved from here, plus the actions each section offers.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/auth/services/auth_service.dart';
import 'package:banigoba/modules/home/models/feed_ranking.dart';
import 'package:banigoba/modules/home/services/area_service.dart';
import 'package:banigoba/modules/onboarding/services/style_preferences_service.dart';
import 'package:banigoba/modules/onboarding/services/username_service.dart';
import 'package:banigoba/modules/onboarding/views/style_preferences_screen.dart';
import 'package:banigoba/modules/onboarding/views/username_screen.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_service.dart';
import 'package:banigoba/modules/provider/views/become_provider_page.dart';
import 'package:banigoba/modules/settings/services/private_account_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/social/widgets/profile_photo_changer.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';
import 'package:banigoba/shared/widgets/consent_sheet.dart';

class SettingsController extends GetxController {
  final TextEditingController name = TextEditingController();
  final TextEditingController street = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController postal = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController currentPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final StorageService _storage = StorageService();
  final AreaService _area = AreaService();

  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final Rx<List<ProviderRole>> providerRoles = Rx<List<ProviderRole>>(const []);
  final RxBool notifyTrending = true.obs;
  final RxBool useLocation = false.obs;
  final RxString profileImageUrl = ''.obs;
  final RxString username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    for (final field in [
      name,
      street,
      city,
      state,
      postal,
      country,
      currentPassword,
      newPassword,
    ]) {
      field.dispose();
    }
    super.onClose();
  }

  void _say(String message) {
    if (isClosed) return;
    AppToast.say(message);
  }

  Future<void> _load() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      if (!isClosed) loading.value = false;
      return;
    }
    final data = await ProfileService().get(user.uid);
    final address = await PrivateAccountService().address(user.uid);
    if (isClosed) return;
    name.text = (data['displayName'] ?? user.displayName ?? '').toString();
    profileImageUrl.value = (data['profileImageUrl'] ?? user.photoURL ?? '')
        .toString();
    username.value = (data['username'] ?? '').toString();
    street.text = (address['street'] ?? '').toString();
    city.text = (data['city'] ?? address['city'] ?? '').toString();
    state.text = (address['state'] ?? '').toString();
    postal.text = (address['postalCode'] ?? '').toString();
    country.text = (address['country'] ?? '').toString();
    providerRoles.value = providerRolesOf(data);
    notifyTrending.value = data['notifyTrending'] != false;
    _area.load(user.uid).then((record) {
      if (!isClosed) useLocation.value = record?.enabled ?? false;
    });
    loading.value = false;
  }

  Future<void> openStylePreferences() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> userData;
    try {
      userData = await ProfileService().get(user.uid);
    } on PostgrestException catch (error) {
      AppToast.say('Unable to load preferences: ${error.message}');
      return;
    }

    final service = StylePreferencesService();
    await Get.to<void>(
      () => StylePreferencesScreen(
        isFirstRun: false,
        initial: StylePreferencesService.fromUserData(userData),
        onSave: (answers) async {
          await service.save(user.uid, answers);
          Get.back<void>();
        },
        onSkip: () async => Get.back<void>(),
      ),
    );
  }

  /// "Near me" from the phone's location: turning on explains first, asks the
  /// phone, and keeps only a rough area; turning off deletes it.
  Future<void> setUseLocation(bool on) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    if (!on) {
      await _area.disable(user.uid);
      if (!isClosed) useLocation.value = false;
      return;
    }
    final context = Get.context;
    if (context == null) return;
    final agreed = await showConsentSheet(
      context,
      title: 'Use my location for Near me',
      points: kLocationConsentText,
    );
    if (!agreed) return;
    final result = await _area.enable(user.uid);
    if (isClosed) return;
    useLocation.value = result == AreaResult.enabled;
    _say(switch (result) {
      AreaResult.enabled => 'Near me now uses your phone\'s location.',
      AreaResult.serviceOff => 'Location is switched off on your phone.',
      AreaResult.denied => 'Banigoba was not allowed to use your location.',
      AreaResult.deniedForever =>
        'Location is blocked for Banigoba. Allow it in your phone settings.',
      AreaResult.failed => 'We could not find your location. Try again.',
    });
  }

  /// Trending-look pushes on or off (at most one a day).
  Future<void> setNotifyTrending(bool on) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    notifyTrending.value = on;
    try {
      await ProfileService().update(user.uid, {'notifyTrending': on});
    } on PostgrestException catch (error) {
      if (!isClosed) notifyTrending.value = !on;
      _say('Unable to change this: ${error.message}');
    }
  }

  /// Opens provider mode, or the one-time sign-up when the user holds no
  /// provider role yet.
  Future<void> openProviderMode() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || saving.value) return;
    if (providerRoles.value.isEmpty) {
      await Get.to<void>(
        () => BecomeProviderPage(suggestedName: name.text.trim()),
      );
      return;
    }
    saving.value = true;
    try {
      await ProviderService().setMode(user.uid, provider: true);
      if (!isClosed) Get.until((route) => route.isFirst);
    } on Exception catch (error) {
      _say('Unable to open business mode: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  Future<void> changeUsername() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    final usernames = UsernameService();
    final current = username.value;
    final updated = await Get.to<String>(
      () => UsernameScreen(
        current: current,
        isFirstRun: false,
        suggest: () => usernames.firstAvailableSuggestion(name.text),
        isAvailable: usernames.isAvailable,
        onClaim: (value) => usernames.claim(userId: user.uid, input: value),
      ),
    );
    if (updated != null && !isClosed) username.value = updated;
  }

  Future<void> pickProfilePicture() async {
    final context = Get.context;
    if (context == null) return;
    saving.value = true;
    try {
      final url = await changeProfilePhoto(
        context,
        picker: _picker,
        storage: _storage,
      );
      if (url != null && !isClosed) profileImageUrl.value = url;
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  Future<void> saveProfile() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || saving.value) return;
    final displayName = name.text.trim();
    if (displayName.isEmpty) {
      _say('Please enter your name.');
      return;
    }

    saving.value = true;
    try {
      final existingAddress = await PrivateAccountService().address(user.uid);
      await Future.wait([
        ProfileService().update(user.uid, {
          'displayName': displayName,
          // The city alone is public, so people near you can find each
          // other (the rest of the address is for delivery).
          'city': city.text.trim(),
          // How people in the same city are matched, spelling aside.
          'cityKey': normalizeCity(city.text),
        }),
        // The address is private, for delivery only.
        PrivateAccountService().saveAddress(user.uid, {
          ...existingAddress,
          'street': street.text.trim(),
          'city': city.text.trim(),
          'state': state.text.trim(),
          'postalCode': postal.text.trim(),
          'country': country.text.trim(),
        }),
      ]);
      _say('Account settings saved.');
    } catch (error) {
      _say('Unable to save settings: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  Future<void> changePassword() async {
    final user = AppAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    final current = currentPassword.text;
    final next = newPassword.text;
    if (current.isEmpty || next.length < 6) {
      _say('Enter your current password and a new password of 6+ characters.');
      return;
    }

    saving.value = true;
    try {
      await AuthService().changePassword(
        email: email,
        currentPassword: current,
        newPassword: next,
      );
      currentPassword.clear();
      newPassword.clear();
      _say('Password updated.');
    } on AuthException catch (error) {
      _say(error.message);
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
