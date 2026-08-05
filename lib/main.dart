import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:jadwal/firebase_options.dart';
import 'package:jadwal/pages/auth/auth_page.dart';
import 'package:jadwal/services/auth_state_service.dart';
import 'package:jadwal/services/connectivity_service.dart';
import 'package:jadwal/services/database_service.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/notification_service.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:jadwal/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load skipped: $e');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize notification service (schedules daily reading/hifdh/review reminders)
  await NotificationService.instance.init();

  final subscriptionService = SubscriptionService();
  await subscriptionService.init();

  // Initialize and preload Quran database in background
  _preloadQuranData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityService()),
        ChangeNotifierProvider(create: (context) => AuthStateService()),
        ChangeNotifierProxyProvider2<ConnectivityService, AuthStateService,
            FirestoreService>(
          create: (context) => FirestoreService(
            auth: FirebaseAuth.instance,
            uid: FirebaseAuth.instance.currentUser?.uid ?? '',
            connectivityService:
                Provider.of<ConnectivityService>(context, listen: false),
          ),
          update: (context, connectivityService, authState, previous) {
            final uid = authState.uid;
            // Reuse the same instance when the signed-in user hasn't changed.
            if (previous != null && previous.uid == uid) {
              return previous;
            }
            previous?.dispose();
            return FirestoreService(
              auth: FirebaseAuth.instance,
              uid: uid,
              connectivityService: connectivityService,
            );
          },
        ),
        ChangeNotifierProvider(create: ((context) => ThemeProvider())),
        ChangeNotifierProvider(create: ((context) => UserPreferencesService())),
        ChangeNotifierProvider(create: ((context) => TutorialService())),
        ChangeNotifierProvider.value(value: subscriptionService),
      ],
      child: const MyApp(),
    ),
  );
}

// Function to preload Quran data in background
Future<void> _preloadQuranData() async {
  // Run in a separate isolate or background task to not block UI
  final dbService = DatabaseService();
  try {
    await dbService.initialize();
    debugPrint('Database preloading completed successfully');
  } catch (e) {
    debugPrint('Error preloading database: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _themePollTimer;
  Brightness? _lastKnownBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Register ShowcaseView for tooltip functionality
    ShowcaseView.register();

    // Initial theme setting with a slight delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brightness = MediaQuery.of(context).platformBrightness;
      _lastKnownBrightness = brightness;
      Provider.of<ThemeProvider>(context, listen: false)
          .updateWithSystemTheme(brightness);

      // Start polling for theme changes when in foreground
      _startThemePolling();
    });
  }

  void _startThemePolling() {
    // Poll every 500ms to check for system theme changes
    _themePollTimer?.cancel();
    _themePollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;

      final currentBrightness = MediaQuery.platformBrightnessOf(context);
      // Only update if brightness actually changed
      if (_lastKnownBrightness != currentBrightness) {
        _lastKnownBrightness = currentBrightness;
        Provider.of<ThemeProvider>(context, listen: false)
            .updateWithSystemTheme(currentBrightness);
      }
    });
  }

  void _stopThemePolling() {
    _themePollTimer?.cancel();
    _themePollTimer = null;
  }

  @override
  void dispose() {
    _stopThemePolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // This is called when the system brightness changes
    final brightness = MediaQuery.platformBrightnessOf(context);
    _lastKnownBrightness = brightness;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateWithSystemTheme(brightness);
    super.didChangePlatformBrightness();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App comes to foreground - check theme and resume polling
      final brightness = MediaQuery.platformBrightnessOf(context);
      _lastKnownBrightness = brightness;
      Provider.of<ThemeProvider>(context, listen: false)
          .updateWithSystemTheme(brightness);
      _startThemePolling();
    } else if (state == AppLifecycleState.paused) {
      // App goes to background - stop polling to save resources
      _stopThemePolling();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
      theme: themeProvider.themeData,
    );
  }
}
