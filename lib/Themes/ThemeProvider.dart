import 'package:flutter/material.dart';
import 'lightMode.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeData _themeData;

  ThemeProvider() : _themeData = clinicLightTheme;

  ThemeData get themeData => _themeData;
  bool get isDarkMode => false;

  Future<void> toggleTheme() async {
    // Theme switching is disabled. Always light mode.
  }
}
