import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color seedColor = Color(0xFF1E5E3D); // Dark green anchor

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ).copyWith(
        primary: seedColor,
        secondary: const Color(0xFFA8D5BA), // Light green accent
        surface: const Color.fromARGB(255, 0, 0, 0), // Deep gray surfaces
        onSurface: Colors.white, // Text/icons on surfaces
      ),

  scaffoldBackgroundColor: seedColor, // Dark green background

  textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme)
      .apply(bodyColor: Colors.white, displayColor: Colors.white)
      .copyWith(
        // override the base fontWeight globally
        bodyLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodySmall: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleSmall: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        labelLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFA8D5BA), // Accent green
      textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: seedColor,
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFA8D5BA),
      side: const BorderSide(color: Color(0xFFA8D5BA)),
      textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: seedColor,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
