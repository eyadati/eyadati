import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Professional clinic blue for interactive elements - original HSL: (210, 0.75, 0.55)
// This is an approximation in RGB. You can fine-tune this if needed.
const Color _primarySeedColor = Color.fromARGB(255, 34, 139, 230);

ThemeData clinicLightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _primarySeedColor,
    brightness: Brightness.light,
    // Using a more greyish/professional tone for secondary elements
    // The original secondary was HSL(210, 0.60, 0.70) which is a lighter blue.
    // Let's let fromSeed handle secondary, but ensure good contrast for onSurface.
    surface: const Color(0xFFFFFFFF), // White
    onSurface: const Color(0xFF1E1E1E), // Dark grey for text on surface
    error: const Color(0xFFB00020), // Standard red for error
    onError: const Color(0xFFFFFFFF), // White text on error
  ),
  // App bar styling
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFFFFFFF), // White
    foregroundColor: const Color(0xFF1E1E1E), // Dark grey
    elevation: 0,
    // For Material 3, consider using systemOverlayStyle if needed for status bar icons
  ),
  // Scaffold background
  scaffoldBackgroundColor: const Color(0xFFF2F2F2), // Light grey
  // Card styling
  cardTheme: CardThemeData(
    color: const Color(0xFFFFFFFF), // White
    elevation: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  // Button styling
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // Background will come from colorScheme.primary
      // Foreground will come from colorScheme.onPrimary
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  // Input fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFFFFFF), // White
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0), // Light grey border
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _primarySeedColor, // Use the primary seed color for focused
        width: 2,
      ),
    ),
  ),
  // Text styling
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.light().textTheme.copyWith(
      bodyLarge: const TextStyle(
        color: Color(0xFF424242), // Darker grey for body text
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        color: Color(0xFF424242), // Darker grey for body text
        height: 1.5,
      ),
      titleLarge: const TextStyle(
        color: Color(0xFF1E1E1E), // Darkest grey for titles
        fontWeight: FontWeight.w600,
      ),
      // Ensure other text styles also have good contrast
    ),
  ),
);
