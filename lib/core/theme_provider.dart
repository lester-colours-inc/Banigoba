// Stores the app's light/dark theme preference and notifies listening widgets.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'dark_mode_enabled';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode = preferences.getBool(_themePreferenceKey) ?? false;
  }

  Future<void> toggleTheme(bool isOn) async {
    if (_isDarkMode == isOn) return;

    _isDarkMode = isOn;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themePreferenceKey, isOn);
  }
}

final themeProvider = ThemeProvider();
