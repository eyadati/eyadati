import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Appointments/utils.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eyadati/flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Supabase.initialize(
      url: "https://erkldarqweehvwgpncrg.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVya2xkYXJxd2VlaHZ3Z3BuY3JnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MTIyMDgsImV4cCI6MjA3NzQ4ODIwOH0.rQPh6hFnn6sz78rLa8_AWU3NV__-EgX8wDOTXbyeQ7o",
    );
    runApp(const EyadatiApp());
  } catch (e) {
    runApp(_buildErrorApp(e.toString()));
  }
}

/// Minimal error screen for initialization failures
Widget _buildErrorApp(String error) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text('initialization_error'.tr(), style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Main app widget
class EyadatiApp extends StatefulWidget {
  const EyadatiApp({super.key});

  @override
  State<EyadatiApp> createState() => _EyadatiAppState();
}

class _EyadatiAppState extends State<EyadatiApp> {
  late Future<Widget> _navigationFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future ONCE at app launch
    _navigationFuture = _initializeAndDecide();
  }

  Future<Widget> _initializeAndDecide() async {
    try {
      // Use the optimized decidePage that checks role first
      final Widget homePage = await decidePage();
      
      // Initialize data caching ONLY for the relevant role
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final isClinic = homePage is Clinichome;
        await AppStartupService().initialize(isClinic);
      }
      
      return homePage;
    } catch (e) {
      debugPrint("Initialization error: $e");
      return intro(); // Fallback to intro on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: FutureBuilder<Widget>(
        future: _navigationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            debugPrint('Navigation error: ${snapshot.error}');
            return Scaffold(body: Center(child: Text('something_went_wrong'.tr())));
          }
          return snapshot.data!;
        },
      ),
    );
  }
}


// Color Palette
class AppColors {
  // Primary Colors
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color skyBlueLight = Color(0xFFB0E0E6);
  static const Color skyBlueDark = Color(0xFF5D9FFF);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color grayLight = Color(0xFFE9ECEF);
  static const Color gray = Color(0xFF6C757D);
  static const Color grayDark = Color(0xFF495057);
  
  // Accent/Contrast Color
  static const Color navyBlue = Color(0xFF003366);
  static const Color navyBlueLight = Color(0xFF004080);
  
  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
}

// Light Theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  
  // Color Scheme
  colorScheme: ColorScheme.light(
    primary: AppColors.skyBlue,
    onPrimary: AppColors.navyBlue,
    primaryContainer: AppColors.skyBlueLight,
    onPrimaryContainer: AppColors.navyBlue,
    
    secondary: AppColors.navyBlue,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.navyBlueLight,
    onSecondaryContainer: AppColors.white,
    
    surface: AppColors.white,
    onSurface: AppColors.navyBlue,
    surfaceVariant: AppColors.offWhite,
    onSurfaceVariant: AppColors.gray,
    
    background: AppColors.offWhite,
    onBackground: AppColors.navyBlue,
    
    error: AppColors.error,
    onError: AppColors.white,
    
    outline: AppColors.grayLight,
  ),
  
  // App Bar Theme
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.navyBlue,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.navyBlue),
    titleTextStyle: TextStyle(
      color: AppColors.navyBlue,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  
  // Scaffold Background Color
  scaffoldBackgroundColor: AppColors.offWhite,
  
  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 2,
    shadowColor: AppColors.gray.withOpacity(0.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  
  // Button Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.skyBlue,
      foregroundColor: AppColors.navyBlue,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.skyBlue,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.navyBlue,
      side: BorderSide(color: AppColors.skyBlue),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  
  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.skyBlue,
    foregroundColor: AppColors.navyBlue,
    elevation: 4,
  ),
  
  // Input Decoration Theme (TextFields)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.grayLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.grayLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.skyBlue, width: 2),
    ),
    labelStyle: TextStyle(color: AppColors.gray),
    hintStyle: TextStyle(color: AppColors.gray),
  ),
  
  // Text Theme
  textTheme: TextTheme(
    displayLarge: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.bold),
    
    headlineLarge: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w600),
    
    titleLarge: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w500),
    
    bodyLarge: TextStyle(color: AppColors.navyBlue),
    bodyMedium: TextStyle(color: AppColors.navyBlue),
    bodySmall: TextStyle(color: AppColors.gray),
    
    labelLarge: TextStyle(color: AppColors.skyBlue, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: AppColors.skyBlue),
    labelSmall: TextStyle(color: AppColors.skyBlue),
  ),
  
  // Icon Theme
  iconTheme: IconThemeData(color: AppColors.navyBlue),
  primaryIconTheme: IconThemeData(color: AppColors.navyBlue),
  
  // Divider Theme
  dividerTheme: DividerThemeData(
    color: AppColors.grayLight,
    thickness: 1,
    space: 1,
  ),
  
  // Bottom Navigation Bar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.white,
    selectedItemColor: AppColors.skyBlue,
    unselectedItemColor: AppColors.gray,
    type: BottomNavigationBarType.fixed,
  ),
  
  // Bottom Sheet
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  
  // Progress Indicators
  progressIndicatorTheme: ProgressIndicatorThemeData(
    linearTrackColor: AppColors.skyBlueLight.withOpacity(0.3),
    color: AppColors.skyBlue,
  ),
  
  // Switch Theme
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.white),
    trackColor: MaterialStateProperty.all(AppColors.skyBlue),
  ),
  
  // Checkbox Theme
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all(AppColors.skyBlue),
    checkColor: MaterialStateProperty.all(AppColors.navyBlue),
  ),
  
  // Radio Theme
  radioTheme: RadioThemeData(
    fillColor: MaterialStateProperty.all(AppColors.skyBlue),
  ),
  
  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.skyBlueLight,
    selectedColor: AppColors.skyBlue,
    labelStyle: TextStyle(color: AppColors.navyBlue),
  ),
  
  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);

// Dark Theme (optional but recommended)
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  
  colorScheme: ColorScheme.dark(
    primary: AppColors.skyBlue,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.skyBlueDark,
    onPrimaryContainer: AppColors.white,
    
    secondary: AppColors.skyBlueLight,
    onSecondary: AppColors.white,
    
    surface: AppColors.darkSurface,
    onSurface: AppColors.white,
    
    background: AppColors.darkBackground,
    onBackground: AppColors.white,
    
    error: AppColors.error,
    onError: AppColors.white,
  ),
  
  scaffoldBackgroundColor: AppColors.darkBackground,
  
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.white,
    elevation: 0,
  ),
  
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    elevation: 2,
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.skyBlue,
      foregroundColor: AppColors.white,
    ),
  ),
  
  // ... (extend other dark theme properties similarly)
);