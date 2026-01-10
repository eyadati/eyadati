import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Appointments/utils.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:eyadati/flow.dart';
import 'package:eyadati/Themes/ThemeProvider.dart'; // Import ThemeProvider
import 'package:lucide_icons/lucide_icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized(); // Initialize EasyLocalization

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await Supabase.initialize(
      url: "https://erkldarqweehvwgpncrg.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVya2xkYXJxd2VlaHZ3Z3BuY3JnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MTIyMDgsImV4cCI6MjA3NzQ4ODIwOH0.rQPh6hFnn6sz78rLa8_AWU3NV__-EgX8wDOTXbyeQ7o",
    );

    // Enable Firestore offline persistence with unlimited cache
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          // Add other providers here if needed
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          path: 'assets/translations', // path to your translations files
          fallbackLocale: const Locale('en'),
          child: const EyadatiApp(),
        ),
      ),
    );
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
              const Icon(
                LucideIcons.alertTriangle,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'initialization_error'.tr(),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
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
      final Widget homePage = await decidePage(context);

      // Initialize data caching ONLY for the relevant role
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final isClinic = homePage is Clinichome;
        await AppStartupService().initialize(isClinic);
      }

      return homePage;
    } catch (e) {
      debugPrint("Initialization error: $e");
      if (!mounted) return const SizedBox.shrink();
      return intro(context); // Fallback to intro on error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData, // Use theme from ThemeProvider
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: FutureBuilder<Widget>(
        future: _navigationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            debugPrint('Navigation error: ${snapshot.error}');
            return Scaffold(
              body: Center(child: Text('something_went_wrong'.tr())),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
