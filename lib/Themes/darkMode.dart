import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simplified color palette for Dark Mode
const Color _darkPrimaryColor = Color(0xFF0A84FF); // A vibrant blue for dark mode
const Color _darkOnPrimaryColor = Colors.white;
const Color _darkSecondaryColor = Color(0xFF1C1C1E); // Dark grey for secondary elements
const Color _darkOnSecondaryColor = Colors.white;
const Color _darkBackgroundColor = Colors.black;
const Color _darkSurfaceColor = Color(0xFF121212); // A slightly lighter black for surfaces
const Color _darkOnSurfaceColor = Colors.white;
const Color _darkErrorColor = Color(0xFFFF453A);
const Color _darkOnErrorColor = Colors.white;

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: _darkPrimaryColor,
    onPrimary: _darkOnPrimaryColor,
    secondary: _darkSecondaryColor,
    onSecondary: _darkOnSecondaryColor,
    error: _darkErrorColor,
    onError: _darkOnErrorColor,
    background: _darkBackgroundColor,
    onBackground: _darkOnSurfaceColor,
    surface: _darkSurfaceColor,
    onSurface: _darkOnSurfaceColor,
  ),
  scaffoldBackgroundColor: _darkBackgroundColor,

  // Typography - Using Inter
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme.copyWith(
          bodyLarge: const TextStyle(color: _darkOnSurfaceColor),
          bodyMedium: const TextStyle(color: _darkOnSurfaceColor),
          titleLarge: const TextStyle(fontWeight: FontWeight.w600, color: _darkOnSurfaceColor),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w500, color: _darkOnSurfaceColor),
        ),
  ),

  // Inputs
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _darkSurfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade800),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _darkPrimaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _darkErrorColor),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _darkErrorColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkPrimaryColor,
      foregroundColor: _darkOnPrimaryColor,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      elevation: 0,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _darkPrimaryColor,
      side: const BorderSide(color: _darkPrimaryColor),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _darkPrimaryColor,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),

  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: _darkBackgroundColor,
    foregroundColor: _darkOnSurfaceColor,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      color: _darkOnSurfaceColor,
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),

  cardTheme: CardTheme(
    color: _darkSurfaceColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade800, width: 1),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
);
