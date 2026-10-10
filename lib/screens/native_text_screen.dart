import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/native_text.dart';
import '../providers/settings_provider.dart';
import '../utils/text_utils.dart';
import '../widgets/audio_mini_player.dart';

class NativeTextScreen extends ConsumerStatefulWidget {
  final NativeSection section;

  const NativeTextScreen({super.key, required this.section});

  @override
  ConsumerState<NativeTextScreen> createState() => _NativeTextScreenState();
}

class _NativeTextScreenState extends ConsumerState<NativeTextScreen> {
  NativeLanguage? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(settingsProvider).selectedLanguage;
  }

  void _showReaderOptions(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier settingsNotifier,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final currentLang = _selectedLanguage ?? settings.selectedLanguage;
            return Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<NativeLanguage>(
                        segments: const [
                          ButtonSegment(
                            value: NativeLanguage.sindhi,
                            label: Text('Sindhi'),
                          ),
                          ButtonSegment(
                            value: NativeLanguage.roman,
                            label: Text('Roman'),
                          ),
                          ButtonSegment(
                            value: NativeLanguage.hindi,
                            label: Text('Hindi'),
                          ),
                        ],
                        selected: {currentLang},
                        onSelectionChanged: (Set<NativeLanguage> newSelection) {
                          setState(() {
                            _selectedLanguage = newSelection.first;
                          });
                          settingsNotifier.setNativeLanguage(
                            newSelection.first,
                          );
                          setStateSheet(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Text Size',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.text_decrease),
                          Expanded(
                            child: Slider(
                              value: settings.fontSizeMultiplier,
                              min: 0.8,
                              max: 1.4,
                              divisions: 3,
                              label: settings.fontSizeMultiplier == 0.8
                                  ? 'Small'
                                  : settings.fontSizeMultiplier == 1.0
                                  ? 'Normal'
                                  : settings.fontSizeMultiplier == 1.2
                                  ? 'Large'
                                  : 'Extra Large',
                              onChanged: (val) {
                                settingsNotifier.setFontSizeMultiplier(val);
                              },
                            ),
                          ),
                          const Icon(Icons.text_increase),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.section.headingRoman),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Reader Options',
            onPressed: () =>
                _showReaderOptions(context, settings, settingsNotifier),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent(settings)),
          const AudioMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildContent(SettingsState settings) {
    final activeLang = _selectedLanguage ?? settings.selectedLanguage;
    final bool hasHindi = widget.section.stanzas.any(
      (s) => s.hindiText != null && s.hindiText!.trim().isNotEmpty,
    );

    if (activeLang == NativeLanguage.hindi && !hasHindi) {
      return Center(
        child: Text(
          'No text available for this language.',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final isSindhi = activeLang == NativeLanguage.sindhi;
    final isHindi = activeLang == NativeLanguage.hindi;
    final heading = isSindhi
        ? widget.section.headingSindhi
        : (isHindi && widget.section.headingHindi != null)
        ? TextUtils.toDevanagariDigits(widget.section.headingHindi!)
        : widget.section.headingRoman;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      children: [
        Text(
          heading,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.0 * settings.fontSizeMultiplier * 1.2,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (isSindhi && widget.section.subheadingSindhi != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.section.subheadingSindhi!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.0 * settings.fontSizeMultiplier * 0.9,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ...widget.section.stanzas.map((stanza) {
          String text = '';
          bool isRtl = false;
          TextAlign tAlign = TextAlign.left;

          if (activeLang == NativeLanguage.sindhi) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final imagePath = isDark
                ? (stanza.sindhiDarkImagePath ?? stanza.sindhiImagePath)
                : (stanza.sindhiImagePath ?? stanza.sindhiDarkImagePath);

            if (imagePath != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  cacheWidth: 1080,
                ),
              );
            }
            text = stanza.sindhiText;
            isRtl = true;
            tAlign = stanza.isCenteredBold ? TextAlign.center : TextAlign.right;
          } else if (activeLang == NativeLanguage.hindi &&
              stanza.hindiText != null) {
            text = TextUtils.toDevanagariDigits(stanza.hindiText!);
            isRtl = false;
            tAlign = TextAlign.center;
          } else {
            text = stanza.romanText;
            isRtl = false;
            tAlign = stanza.isCenteredBold ? TextAlign.center : TextAlign.left;
          }

          if (text.trim().isEmpty) return const SizedBox.shrink();

          final String? stanzaNumDisplay = stanza.stanzaNumber != null
              ? (activeLang == NativeLanguage.hindi
                    ? TextUtils.toDevanagariDigits(
                        stanza.stanzaNumber.toString(),
                      )
                    : stanza.stanzaNumber.toString())
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stanzaNumDisplay != null && stanzaNumDisplay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '── $stanzaNumDisplay ──',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0 * settings.fontSizeMultiplier,
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildHighlightedText(
                  text,
                  textAlign: tAlign,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  defaultStyle: TextStyle(
                    fontSize: stanza.isCenteredBold
                        ? (16.0 * settings.fontSizeMultiplier) * 1.2
                        : (16.0 * settings.fontSizeMultiplier),
                    fontWeight: stanza.isCenteredBold
                        ? FontWeight.bold
                        : FontWeight.normal,
                    height: 1.8,
                    color: stanza.isCenteredBold
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHighlightedText(
    String text, {
    required TextStyle defaultStyle,
    required TextAlign textAlign,
    required TextDirection textDirection,
  }) {
    final RegExp exp = RegExp(r'(هري اوم|Hari Om)', caseSensitive: false);
    final Iterable<RegExpMatch> matches = exp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        textAlign: textAlign,
        textDirection: textDirection,
        style: defaultStyle,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hariOmColor = isDark
        ? const Color.fromRGBO(221, 125, 59, 1)
        : const Color(0xFF9A3A16);

    final List<TextSpan> spans = [];
    int start = 0;
    for (final RegExpMatch match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: defaultStyle.copyWith(
            color: hariOmColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spans, style: defaultStyle),
      textAlign: textAlign,
      textDirection: textDirection,
    );
  }
}
