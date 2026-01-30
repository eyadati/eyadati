import 'package:eyadati/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:eyadati/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:eyadati/flow.dart';
import 'package:eyadati/Themes/ThemeProvider.dart'; // Import ThemeProvider
import 'package:eyadati/utils/connectivity_service.dart'; // Import ConnectivityService
import 'package:lucide_icons/lucide_icons.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
  // You can show a local notification here if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for notifications (iOS and Web)
    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await Supabase.initialize(
      url: "https://erkldarqweehvwgpncrg.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVya2xkYXJxd2VlaHZ3Z3BuY3JnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MTIyMDgsImV4cCI6MjA3NzQ4ODIwOH0.rQPh6hFnn6sz78rLa8_AWU3NV__-EgX8wDOTXbyeQ7o",
    );

    // SEED DATA (Run once or use fix function)
    // DataSeeder.seedClinics();
    // DataSeeder.fixSeedData();

    // Enable Firestore offline persistence with unlimited cache
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityService()),
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
    runApp(
      MaterialApp(
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
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    _navigationFuture = _initializeAndDecide();
  }

  Future<Widget> _initializeAndDecide() async {
    try {
      final Widget homePage = await decidePage(context);
      return homePage;
    } catch (e) {
      debugPrint("Initialization error: $e");
      if (!mounted) return const SizedBox.shrink();
      return intro(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: FutureBuilder<Widget>(
        future: _navigationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else if (snapshot.hasError) {
            debugPrint("Error loading initial page: ${snapshot.error}");
            return intro(context); // Fallback to intro on error
          } else if (snapshot.hasData) {
            return snapshot.data!;
          }
          return SplashScreen(); // Fallback
        },
      ),
    );
  }
}
