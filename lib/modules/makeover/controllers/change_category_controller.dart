// Which category a look or piece is being moved to.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ChangeCategoryController extends GetxController {
  ChangeCategoryController({required this.currentCategory})
    : selected = currentCategory.trim().obs;

  final String currentCategory;
  final RxString selected;
  final TextEditingController newCategory = TextEditingController();
  // Mirrors [newCategory] so the view reacts to typing.
  final RxString typed = ''.obs;

  @override
  void onInit() {
    super.onInit();
    newCategory.addListener(() => typed.value = newCategory.text);
  }

  /// A typed new category wins over a chip.
  String get chosen {
    final text = typed.value.trim();
    return text.isNotEmpty ? text : selected.value;
  }

  bool get changed => chosen != currentCategory.trim();

  void choose(String option) {
    selected.value = option;
    newCategory.clear();
  }

  @override
  void onClose() {
    newCategory.dispose();
    super.onClose();
  }
}
