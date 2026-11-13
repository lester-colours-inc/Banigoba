// Edit Profile: the person's name, city, gender and date of birth. Name and
// city are public; gender and date of birth are private (owner-only) and only
// shape suggestions, such as which clothes the shop shows first.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/home/models/feed_ranking.dart';
import 'package:banigoba/modules/settings/services/private_account_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Youngest age allowed to hold an account.
const int kMinimumAge = 13;

/// Gender choices: stored value and label.
const Map<String, String> kGenderOptions = {
  'male': 'Male',
  'female': 'Female',
  'non_binary': 'Non-binary',
  'prefer_not': 'Prefer not to say',
};

/// An error for [dob] on [today], or null when it is unset or fine.
String? validateDateOfBirth(DateTime? dob, DateTime today) {
  if (dob == null) return null;
  if (dob.isAfter(today)) return 'Date of birth can\'t be in the future.';
  final age = PersonalDetails(dateOfBirth: dob).ageOn(today) ?? 0;
  if (age < kMinimumAge) return 'You must be at least $kMinimumAge.';
  if (age > 120) return 'Please check your date of birth.';
  return null;
}

class EditProfileController extends GetxController {
  final TextEditingController name = TextEditingController();
  final TextEditingController city = TextEditingController();

  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxnString gender = RxnString();
  final Rxn<DateTime> dateOfBirth = Rxn<DateTime>();
  final RxString username = ''.obs;
  final RxString photoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    name.dispose();
    city.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      loading.value = false;
      return;
    }
    try {
      final data = await ProfileService().get(user.uid);
      final details = await PrivateAccountService().details(user.uid);
      if (isClosed) return;
      name.text = (data['displayName'] ?? user.displayName ?? '').toString();
      city.text = (data['city'] ?? '').toString();
      username.value = (data['username'] ?? '').toString();
      photoUrl.value = (data['profileImageUrl'] ?? user.photoURL ?? '')
          .toString();
      gender.value = details.gender;
      dateOfBirth.value = details.dateOfBirth;
    } on Object {
      AppToast.say('Unable to load your details.');
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  void setGender(String? value) => gender.value = value;

  Future<void> pickDateOfBirth(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          dateOfBirth.value ??
          DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Date of birth',
    );
    if (picked != null) dateOfBirth.value = picked;
  }

  void clearDateOfBirth() => dateOfBirth.value = null;

  Future<void> save() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || saving.value) return;
    final displayName = name.text.trim();
    if (displayName.isEmpty) {
      AppToast.say('Please enter your name.');
      return;
    }
    final dobError = validateDateOfBirth(dateOfBirth.value, DateTime.now());
    if (dobError != null) {
      AppToast.say(dobError);
      return;
    }
    saving.value = true;
    try {
      await Future.wait([
        ProfileService().update(user.uid, {
          'displayName': displayName,
          'city': city.text.trim(),
          'cityKey': normalizeCity(city.text),
        }),
        PrivateAccountService().saveDetails(
          user.uid,
          PersonalDetails(gender: gender.value, dateOfBirth: dateOfBirth.value),
        ),
      ]);
      AppToast.say('Profile updated.');
      Get.back<void>(result: true);
    } on Object catch (error) {
      AppToast.say('Unable to save your profile: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
