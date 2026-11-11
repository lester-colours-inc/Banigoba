// Writing the words for a quote: the text and whether it can go on.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class QuoteController extends GetxController {
  final TextEditingController text = TextEditingController();

  /// Mirrors [text] so the view reacts to typing.
  final RxString typed = ''.obs;

  bool get canContinue => typed.value.trim().isNotEmpty;

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}
