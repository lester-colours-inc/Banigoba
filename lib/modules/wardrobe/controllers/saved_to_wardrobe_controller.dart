// The "Saved to My Smart Wardrobe" sheet: which look category is picked.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Suggested when the user has no categories of their own yet.
const List<String> kStarterLookCategories = [
  'Work',
  'Church',
  'Weddings',
  'Weekend',
  'Date night',
];

class SavedToWardrobeController extends GetxController {
  SavedToWardrobeController({required this.existingCategories});

  final List<String> existingCategories;

  final TextEditingController newCategory = TextEditingController();
  final RxString selected = ''.obs;
  // Mirrors [newCategory] so the view reacts to typing.
  final RxString typed = ''.obs;

  List<String> get options =>
      existingCategories.isEmpty ? kStarterLookCategories : existingCategories;

  /// A typed category wins over a picked chip.
  String get chosen {
    final text = typed.value.trim();
    return text.isNotEmpty ? text : selected.value;
  }

  @override
  void onInit() {
    super.onInit();
    newCategory.addListener(() => typed.value = newCategory.text);
  }

  void toggle(String option, {required bool isSelected}) =>
      selected.value = isSelected ? option : '';

  @override
  void onClose() {
    newCategory.dispose();
    super.onClose();
  }
}
