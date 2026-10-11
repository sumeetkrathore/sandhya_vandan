import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandhya_vandan/providers/audio_provider.dart';
import 'package:sandhya_vandan/providers/settings_provider.dart';
import 'package:sandhya_vandan/screens/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudioNotifier extends AudioProviderNotifier {
  @override
  AudioState build() {
    return AudioState();
  }
}

void main() {
  testWidgets('ReaderScreen opens Reader Preferences and toggles reading mode without error',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        audioProvider.overrideWith(() => FakeAudioNotifier()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ReaderScreen(initialSectionIndex: 0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Default reading mode is pageSwipe
    expect(container.read(settingsProvider).readingMode, ReadingMode.pageSwipe);

    // Find the Reader Preferences icon button (Icons.tune_rounded)
    final prefButton = find.byTooltip('Reader Preferences');
    expect(prefButton, findsOneWidget);

    // Tap the Reader Preferences button
    await tester.tap(prefButton);
    await tester.pumpAndSettle();

    // Verify Reader Preferences sheet opened
    expect(find.text('Reader Preferences'), findsOneWidget);
    expect(find.text('Reading Mode'), findsOneWidget);
    expect(find.text('Page Turn'), findsOneWidget);
    expect(find.text('Continuous Scroll'), findsOneWidget);

    // Tap Continuous Scroll
    await tester.tap(find.text('Continuous Scroll'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).readingMode, ReadingMode.continuousScroll);

    // Tap Page Turn
    await tester.tap(find.text('Page Turn'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).readingMode, ReadingMode.pageSwipe);

    // Close preferences sheet
    final closeButton = find.byIcon(Icons.close_rounded).last;
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // Advance remaining timers if any
    await tester.pump(const Duration(seconds: 3));
  });
}
