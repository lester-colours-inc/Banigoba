// The "edit your look" sheet: which item, and how to change it.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/models/look_request.dart';

class LookEditController extends GetxController {
  LookEditController({required this.fixedPart, required LookPart initialPart})
    : part = (fixedPart ?? initialPart).obs;

  final LookPart? fixedPart;
  final Rx<LookPart> part;
  final TextEditingController note = TextEditingController();
  // Mirrors [note] so the view reacts to typing.
  final RxString typed = ''.obs;

  bool get isTweak => fixedPart != null;

  bool get canApply => !isTweak || typed.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    note.addListener(() => typed.value = note.text);
  }

  @override
  void onClose() {
    note.dispose();
    super.onClose();
  }
}
