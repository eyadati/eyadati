import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simplified color palette for Light Mode
const Color _lightPrimaryColor = Color(0xFF007AFF); // A clean, standard blue
const Color _lightOnPrimaryColor = Colors.white;
const Color _lightSecondaryColor = Color(0xFFE5E5EA); // Light grey for secondary elements
const Color _lightOnSecondaryColor = Colors.black;
const Color _lightBackgroundColor = Colors.white;
const Color _lightSurfaceColor = Color(0xFFF2F2F7); // Slightly off-white for surfaces
const Color _lightOnSurfaceColor = Colors.black;
const Color _lightErrorColor = Color(0xFFFF3B30);
const Color _lightOnErrorColor = Colors.white;

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: _lightPrimaryColor,
    onPrimary: _lightOnPrimaryColor,
    secondary: _lightSecondaryColor,
    onSecondary: _lightOnSecondaryColor,
    error: _lightErrorColor,
    onError: _lightOnErrorColor,
    background: _lightBackgroundColor,
    onBackground: _lightOnSurfaceColor,
    surface: _lightSurfaceColor,
    onSurface: _lightOnSurfaceColor,
  ),
  scaffoldBackgroundColor: _lightBackgroundColor,

  // Typography - Using Inter
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.light().textTheme.copyWith(
          bodyLarge: const TextStyle(color: _lightOnSurfaceColor),
          bodyMedium: const TextStyle(color: _lightOnSurfaceColor),
          titleLarge: const TextStyle(fontWeight: FontWeight.w600, color: _lightOnSurfaceColor),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w500, color: _lightOnSurfaceColor),
        ),
  ),

  // Inputs
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _lightSurfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _lightPrimaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _lightErrorColor),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _lightErrorColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightPrimaryColor,
      foregroundColor: _lightOnPrimaryColor,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      elevation: 0,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _lightPrimaryColor,
      side: const BorderSide(color: _lightPrimaryColor),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _lightPrimaryColor,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),

  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: _lightBackgroundColor,
    foregroundColor: _lightOnSurfaceColor,
    elevation: 0, // Flat design
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      color: _lightOnSurfaceColor,
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),

  cardTheme: CardTheme(
    color: _lightSurfaceColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
);
