import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/settings_provider.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/audio_handler.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/notification_router.dart';
import 'firebase_options.dart';

late final AudioHandler audioHandler;

// Declare a global Future that SplashScreen can await
late final Future<void> appInitialization;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set strict memory bounds on Flutter imageCache to prevent bitmap memory bloat,
  // GC thrashing, and Low Memory Killer (LMK) / OutOfMemory crashes on Android.
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      40 * 1024 * 1024; // 40 MB max

  // Global uncaught error guard to prevent any unhandled exception from crashing the app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("FlutterError caught: ${details.exceptionAsString()}");
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint("PlatformDispatcher caught error: $error");
    return true; // Prevents app termination
  };

  // SharedPreferences is extremely fast and must be loaded before ProviderScope
  final sharedPreferences = await SharedPreferences.getInstance();

  // Start heavy initializations in the background
  appInitialization = _initializeServices(sharedPreferences);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SandyaVandanApp(),
    ),
  );
}

Future<void> _initializeServices(SharedPreferences sharedPreferences) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    audioHandler = await AudioService.init(
      builder: () => SandyaVandanAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.jaisamadha.sandyavandan.channel.audio',
        androidNotificationChannelName: 'Sandhya Vandan Audio',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );

    final notificationService = NotificationService();
    await notificationService.init();

    if (sharedPreferences.getBool('dailyNotificationsEnabled') ?? true) {
      final granted = await notificationService.requestPermissions();
      if (granted) {
        notificationService.scheduleSandhyaReminder();
      }
    }

    // Initialize Push Notification Service
    PushNotificationService().init();
  } catch (e) {
    debugPrint("Background initialization error: $e");
  }
}

class SandyaVandanApp extends ConsumerWidget {
  const SandyaVandanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      navigatorKey: NotificationRouter.navigatorKey,
      title: 'Sandhya Vandan',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      themeAnimationDuration: Duration.zero,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
