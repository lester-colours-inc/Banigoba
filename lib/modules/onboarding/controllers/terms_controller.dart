import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/shared/widgets/app_toast.dart';

class TermsController extends GetxController {
  TermsController({required this.onAccept});

  final Future<void> Function() onAccept;

  final RxBool agreed = false.obs;
  final RxBool saving = false.obs;

  void setAgreed(bool? value) => agreed.value = value ?? false;

  bool get canContinue => agreed.value && !saving.value;

  Future<void> accept() async {
    saving.value = true;
    try {
      await onAccept();
    } on Exception catch (error) {
      debugPrint('Unable to save Terms acceptance: $error');
      AppToast.say('Could not save. Please try again.');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
