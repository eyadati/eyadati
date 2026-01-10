import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData clinicLightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    // Professional clinic blue for interactive elements
    primary: HSLColor.fromAHSL(1.0, 210, 0.75, 0.55).toColor(),
    onPrimary: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(), // white
    
    // Secondary for less prominent actions
    secondary: HSLColor.fromAHSL(1.0, 210, 0.60, 0.70).toColor(),
    onSecondary: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
    
    // Error state
    error: HSLColor.fromAHSL(1.0, 0, 0.8, 0.55).toColor(),
    onError: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
    
    // Clean surface colors
    surface: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(), // white
    onSurface: HSLColor.fromAHSL(1.0, 0, 0, 0.05).toColor(),
  ),
  
  // App bar styling
  appBarTheme: AppBarTheme(
    backgroundColor: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
    foregroundColor: HSLColor.fromAHSL(1.0, 0, 0, 0.05).toColor(),
    elevation: 0,
  ),
  
  // Scaffold background
  scaffoldBackgroundColor: HSLColor.fromAHSL(1.0, 0, 0, 0.95).toColor(),
  
  // Card styling
  cardTheme: CardThemeData(
    color: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
    elevation: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  
  // Button styling
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: HSLColor.fromAHSL(1.0, 210, 0.75, 0.55).toColor(),
      foregroundColor: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  
  // Input fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: HSLColor.fromAHSL(1.0, 0, 0, 0.90).toColor(),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: HSLColor.fromAHSL(1.0, 210, 0.75, 0.55).toColor(),
        width: 2,
      ),
    ),
  ),
  
  // Text styling
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.light().textTheme.copyWith(
      bodyLarge: TextStyle(
        color: HSLColor.fromAHSL(1.0, 0, 0, 0.30).toColor(),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: HSLColor.fromAHSL(1.0, 0, 0, 0.30).toColor(),
        height: 1.5,
      ),
      titleLarge: TextStyle(
        color: HSLColor.fromAHSL(1.0, 0, 0, 0.05).toColor(),
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);