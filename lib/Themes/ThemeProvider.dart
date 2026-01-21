import 'package:flutter/material.dart';
import 'darkMode.dart';
import 'lightMode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider() : _themeData = clinicLightTheme {
    // Initialize with a default theme, then load from preferences
    _loadThemeFromPrefs();
  }

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData == darkMode;

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    if (_themeData != (isDark ? darkMode : clinicLightTheme)) {
      _themeData = isDark ? darkMode : clinicLightTheme;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeData == clinicLightTheme) {
      _themeData = darkMode;
      await prefs.setBool('isDarkMode', true);
    } else {
      _themeData = clinicLightTheme;
      await prefs.setBool('isDarkMode', false);
    }
    notifyListeners();
  }
}
