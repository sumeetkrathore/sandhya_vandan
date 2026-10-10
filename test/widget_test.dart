import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandhya_vandan/data/native_text_data.dart';
import 'package:sandhya_vandan/providers/settings_provider.dart';
import 'package:sandhya_vandan/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Native text data integrity test', () {
    expect(nativeSections, isNotEmpty);
    expect(nativeSections.first.id, equals('MANGALA_CHARAN'));
  });

  test('SettingsProvider default state test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final settings = container.read(settingsProvider);
    expect(settings.fontSizeMultiplier, equals(1.0));
  });

  testWidgets('SettingsScreen renders without assertion errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('READING EXPERIENCE'), findsOneWidget);
    expect(find.text('APP SETTINGS'), findsOneWidget);
  });
}
