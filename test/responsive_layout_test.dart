import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sandhya_vandan/screens/home_screen.dart';
import 'package:sandhya_vandan/screens/reader_screen.dart';
import 'package:sandhya_vandan/screens/wisdom_screen.dart';
import 'package:sandhya_vandan/screens/settings_screen.dart';
import 'package:sandhya_vandan/screens/ashrams_screen.dart';
import 'package:sandhya_vandan/screens/satgurus_screen.dart';
import 'package:sandhya_vandan/screens/onboarding_screen.dart';
import 'package:sandhya_vandan/theme/app_theme.dart';
import 'package:sandhya_vandan/providers/settings_provider.dart';
import 'package:sandhya_vandan/providers/audio_provider.dart';

class FakeAudioNotifier extends AudioProviderNotifier {
  @override
  AudioState build() {
    return AudioState();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock platform channel values for package_info_plus & path_provider
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Sandhya Vandan',
      packageName: 'com.samadhaashram.sandhyavandan',
      version: '1.1.3',
      buildNumber: '2027',
      buildSignature: '',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory' ||
            methodCall.method == 'getTemporaryDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  final displaySizes = [
    const Size(320, 568), // Small Phone
    const Size(375, 667), // Standard SE
    const Size(390, 844), // Standard iPhone
    const Size(430, 932), // Large Phone
    const Size(768, 1024), // Tablet / iPad
  ];

  final textScales = [1.0, 1.3, 1.5];

  final screenMap = <String, Widget Function()>{
    'HomeScreen': () => const HomeScreen(),
    'ReaderScreen': () => const ReaderScreen(initialSectionIndex: 0),
    'WisdomScreen': () => const WisdomScreen(),
    'SettingsScreen': () => const SettingsScreen(),
    'AshramsScreen': () => const AshramsScreen(),
    'SatgurusScreen': () => const SatgurusScreen(),
    'OnboardingScreen': () => const OnboardingScreen(),
  };

  group('Full Application Multi-Screen Responsive Layout Matrix Tests', () {
    for (final entry in screenMap.entries) {
      final screenName = entry.key;
      final screenBuilder = entry.value;

      for (final size in displaySizes) {
        for (final textScale in textScales) {
          for (final isDark in [false, true]) {
            testWidgets(
              '$screenName layout overflow check at ${size.width.toInt()}x${size.height.toInt()}, scale ${textScale}x, dark=$isDark',
              (WidgetTester tester) async {
                SharedPreferences.setMockInitialValues({
                  'remember_language_choice': true,
                });
                final prefs = await SharedPreferences.getInstance();

                tester.view.devicePixelRatio = 1.0;
                tester.view.physicalSize = size;
                addTearDown(tester.view.resetDevicePixelRatio);
                addTearDown(tester.view.resetPhysicalSize);

                await tester.pumpWidget(
                  ProviderScope(
                    overrides: [
                      sharedPreferencesProvider.overrideWithValue(prefs),
                      audioProvider.overrideWith(() => FakeAudioNotifier()),
                    ],
                    child: MaterialApp(
                      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
                      home: MediaQuery(
                        data: MediaQueryData(
                          size: size,
                          textScaler: TextScaler.linear(textScale),
                        ),
                        child: screenBuilder(),
                      ),
                    ),
                  ),
                );

                await tester.pump(const Duration(seconds: 3));
                expect(tester.takeException(), isNull);
              },
            );
          }
        }
      }
    }
  });
}
