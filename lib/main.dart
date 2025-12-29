import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/firebase_options.dart';
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
class EyadatiApp extends StatelessWidget {
  const EyadatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FutureBuilder<Widget>(
        future: decidePage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data ?? Text('something_went_wrong'.tr());
        },
      ),
    );
  }
}

/// Theme configuration
abstract final class AppTheme {
  static ThemeData light = FlexThemeData.light(
    scheme: FlexScheme.deepBlue,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}