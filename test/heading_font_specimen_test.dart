import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandhya_vandan/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load custom fonts into TestWidgetsFlutterBinding
    final fontManifest = [
      {
        'family': 'FedraSerifA',
        'files': [
          'assets/fonts/FedraSerifA-Normal.otf',
          'assets/fonts/FedraSerifA-Medium.otf',
          'assets/fonts/FedraSerifA-Bold.ttf',
        ]
      },
      {
        'family': 'FedraSansPro',
        'files': [
          'assets/fonts/FedraSansPro-Regular.ttf',
          'assets/fonts/FedraSansPro-Medium.ttf',
          'assets/fonts/FedraSansPro-Bold.ttf',
        ]
      },
      {
        'family': 'SaremAsifa',
        'files': ['assets/fonts/Sarem Asifa Bold.ttf']
      },
      {
        'family': 'MBSaremIqra',
        'files': ['assets/fonts/MBSaremIqra.ttf']
      },
    ];

    for (final font in fontManifest) {
      final loader = FontLoader(font['family'] as String);
      for (final path in font['files'] as List<String>) {
        final file = File(path);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        }
      }
      await loader.load();
    }
  });

  const headingSampleRoman = 'Sandhya Vandan - Samadha Ashram';
  const headingSampleHindi = 'संध्या वंदन - समधा आश्रम';
  const headingSampleSindhi = 'سنڌيا وندن - سمڌا آشرم';

  final languages = [
    {'name': 'Roman', 'text': headingSampleRoman, 'dir': TextDirection.ltr},
    {'name': 'Hindi', 'text': headingSampleHindi, 'dir': TextDirection.ltr},
    {'name': 'Sindhi', 'text': headingSampleSindhi, 'dir': TextDirection.rtl},
  ];

  final textScales = [1.0, 2.0];

  group('Heading Font Specimen Rendering Tests', () {
    for (final isDark in [false, true]) {
      final themeName = isDark ? 'Dark' : 'Light';

      for (final textScale in textScales) {
        testWidgets(
          'Render Heading Specimen Matrix - $themeName Theme, Scale ${textScale}x',
          (WidgetTester tester) async {
            tester.view.devicePixelRatio = 1.0;
            tester.view.physicalSize = Size(600, 1400 * textScale);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);

            final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                debugShowCheckedModeBanner: false,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(600, 1400 * textScale),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                        'Heading Specimen ($themeName Theme ${textScale}x)',
                      ),
                    ),
                    body: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final lang in languages) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '=== Language: ${lang['name']} ===',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ),
                          Directionality(
                            textDirection: lang['dir'] as TextDirection,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. App Bar Title
                                    const Text(
                                      'Role: App Bar Title',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      lang['text'] as String,
                                      style: lang['name'] == 'Sindhi'
                                          ? const TextStyle(
                                              fontFamily: AppTheme.sindhiHeadingFont,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : AppTheme.appBarTitle,
                                    ),
                                    const SizedBox(height: 12),

                                    // 2. Sheet / Dialog Title
                                    const Text(
                                      'Role: Sheet / Dialog Title',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      lang['text'] as String,
                                      style: lang['name'] == 'Sindhi'
                                          ? const TextStyle(
                                              fontFamily: AppTheme.sindhiHeadingFont,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : AppTheme.sheetTitle,
                                    ),
                                    const SizedBox(height: 12),

                                    // 3. Card Title
                                    const Text(
                                      'Role: Card Title',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      lang['text'] as String,
                                      style: lang['name'] == 'Sindhi'
                                          ? const TextStyle(
                                              fontFamily: AppTheme.sindhiHeadingFont,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : AppTheme.cardTitleMain,
                                    ),
                                    const SizedBox(height: 12),

                                    // 4. Section Label
                                    const Text(
                                      'Role: Section Label',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      (lang['text'] as String).toUpperCase(),
                                      style: lang['name'] == 'Sindhi'
                                          ? const TextStyle(
                                              fontFamily: AppTheme.sindhiHeadingFont,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : AppTheme.sectionHeader,
                                    ),
                                    const SizedBox(height: 12),

                                    // 5. List Tile Title
                                    const Text(
                                      'Role: List Tile Title',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        lang['text'] as String,
                                        style: lang['name'] == 'Sindhi'
                                            ? const TextStyle(
                                                fontFamily: AppTheme.sindhiHeadingFont,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              )
                                            : AppTheme.cardTitleCompact,
                                      ),
                                      subtitle: const Text('Subtitle sample text'),
                                      leading: const Icon(Icons.bookmark_rounded),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();
            final fileName =
                'heading_specimen_${themeName.toLowerCase()}_scale_${textScale.toInt()}x.png';
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/$fileName'),
            );
          },
        );
      }
    }
  });
}
