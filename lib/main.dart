import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Appointments/booking_logic.dart';
import 'package:eyadati/clinic/clinicRegisterUi.dart';
import 'package:eyadati/clinic/clinicSettingsPage.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:eyadati/firebase_options.dart';
import 'package:eyadati/flow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: "https://erkldarqweehvwgpncrg.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVya2xkYXJxd2VlaHZ3Z3BuY3JnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MTIyMDgsImV4cCI6MjA3NzQ4ODIwOH0.rQPh6hFnn6sz78rLa8_AWU3NV__-EgX8wDOTXbyeQ7o",
  );
 
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(body: const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final clinicUid = FirebaseAuth.instance.currentUser?.uid;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ClinicAppointmentProvider(clinicId: clinicUid!),
        ),
        ChangeNotifierProvider(create: (_) => BookingLogic()),
        ChangeNotifierProvider(create: (_) => ClinicsettingProvider()),
        ChangeNotifierProvider(create: (_) => ClinicOnboardingProvider()),
      ],
      child: SafeArea(
        child: FutureBuilder<Widget>(
          future: decidePage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            return Container(
              child: snapshot.data ?? Text('Something went wrong'.tr()),
            );
          },
        ),
      ),
    );
  }
}











abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // Using FlexColorScheme built-in FlexScheme enum based colors
    scheme: FlexScheme.deepBlue,
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );}