// Holds the light/dark theme preference and persists it across launches.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _preferenceKey = 'dark_mode_enabled';

  final RxBool isDarkMode = false.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// Loads the saved preference. Call before `runApp` so the first frame is
  /// already in the right theme.
  Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    isDarkMode.value = preferences.getBool(_preferenceKey) ?? false;
    return this;
  }

  Future<void> setDarkMode(bool isOn) async {
    if (isDarkMode.value == isOn) return;
    isDarkMode.value = isOn;
    Get.changeThemeMode(themeMode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, isOn);
  }

  Future<void> toggle() => setDarkMode(!isDarkMode.value);
}
