// Settings › Privacy & safety: the AI photo switch and deleting the account.
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class PrivacySafetyController extends GetxController {
  PrivacySafetyController({SafetyService? safety})
    : _safety = safety ?? SafetyService.instance;

  final SafetyService _safety;

  /// Whether AI may use the user's photos; null until read.
  final Rxn<bool> aiAllowed = Rxn<bool>();
  final RxBool deleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _safety.hasAiPhotoConsent().then(
      (allowed) {
        if (!isClosed) aiAllowed.value = allowed;
      },
      onError: (Object error) {
        debugPrint('Unable to read AI consent: $error');
        if (!isClosed) aiAllowed.value = false;
      },
    );
  }

  Future<void> setAi(bool allowed) async {
    final before = aiAllowed.value;
    aiAllowed.value = allowed;
    try {
      await _safety.setAiPhotoConsent(allowed);
    } on Exception catch (error) {
      debugPrint('Unable to save AI consent: $error');
      if (isClosed) return;
      aiAllowed.value = before;
      AppToast.say('Could not save. Please try again.');
    }
  }

  /// Deletes the account after the user confirmed it.
  Future<void> deleteAccount() async {
    deleting.value = true;
    try {
      await _safety.deleteAccount();
      if (isClosed) return;
      // Signed out: back to the start, where the sign-in screen shows.
      Get.until((route) => route.isFirst);
    } on Exception catch (error) {
      if (isClosed) return;
      deleting.value = false;
      AppToast.say(error.toString().replaceFirst('Exception: ', ''));
    }
  }
}
