// The "type DELETE" box: ready only once the word is typed.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class DeleteConfirmController extends GetxController {
  final TextEditingController text = TextEditingController();
  final RxString typed = ''.obs;

  bool get ready => typed.value.trim().toUpperCase() == 'DELETE';

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}
