import 'package:flutter/material.dart';
import 'darkMode.dart';
import 'lightMode.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = clinicLightTheme;
  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData == darkMode;
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == clinicLightTheme) {
      themeData = darkMode;
    } else {
      themeData = clinicLightTheme;
    }
  }
}
