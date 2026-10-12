import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandhya_vandan/data/native_text_data.dart';
import 'package:sandhya_vandan/models/native_text.dart';
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
  test('Native text data has complete Hindi, Roman, and Sindhi content', () {
    expect(nativeSections.length, equals(10));

    for (final section in nativeSections) {
      expect(section.headingSindhi.trim(), isNotEmpty);
      expect(section.headingRoman.trim(), isNotEmpty);
      expect(section.headingHindi?.trim(), isNotEmpty);
      expect(section.stanzas, isNotEmpty);

      // Check Hindi stanzas are present
      final hindiStanzas = section.stanzas
          .where((s) => s.hindiText != null && s.hindiText!.trim().isNotEmpty);
      expect(
        hindiStanzas,
        isNotEmpty,
        reason: 'Section ${section.id} should have Hindi stanzas',
      );

      // Check Roman stanzas are present
      final romanStanzas = section.stanzas
          .where((s) => s.romanText.trim().isNotEmpty);
      expect(
        romanStanzas,
        isNotEmpty,
        reason: 'Section ${section.id} should have Roman stanzas',
      );
    }
  });

  testWidgets('ReaderScreen displays Hindi Devanagari text when Hindi is active',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedLanguage': NativeLanguage.hindi.index,
    });
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

    // Verify "Preview not available" is NOT displayed
    expect(find.text('Preview not available'), findsNothing);

    // Verify Hindi heading is displayed
    expect(find.text('मंगला चरण'), findsWidgets);

    // Advance remaining timers if any
    await tester.pump(const Duration(seconds: 3));
  });
}
