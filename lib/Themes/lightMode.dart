import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color dellGreen = Color(0xFF007D4C);
const Color sulu = Color(0xFFA8E6A3);
const Color backgroundColor = Color(0xFFF8FAF9);
const Color surfaceVariant = Color(0xFFEEF2F3);
const Color textPrimary = Color(0xFF1F2937);

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,

  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: dellGreen,
    onPrimary: Colors.white,
    secondary: sulu,
    onSecondary: textPrimary,
    surface: Colors.white,
    onSurface: textPrimary,
    error: Color(0xFFC62828),
    onError: Colors.white,
  ),

  scaffoldBackgroundColor: backgroundColor,

  // Typography
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.light().textTheme.copyWith(
      bodyLarge: const TextStyle(color: textPrimary),
      bodyMedium: const TextStyle(color: textPrimary),
      titleLarge: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),

  // Inputs
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: dellGreen.withValues(alpha: 0.4)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: dellGreen, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFC62828)),
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: dellGreen,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      elevation: 0,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: dellGreen,
      side: const BorderSide(color: dellGreen),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: dellGreen,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: false,
  ),

  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
