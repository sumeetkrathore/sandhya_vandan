import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/native_text.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

class NativeSectionWidget extends StatelessWidget {
  static final RegExp _hariOmExp = RegExp(
    r'(هري اوم|Hari Om)',
    caseSensitive: false,
  );

  final NativeSection section;
  final NativeLanguage selectedLanguage;
  final double fontSizeMultiplier;
  final bool isContinuous;
  final String? canonicalPageReference;
  final ScrollPhysics? scrollPhysics;

  const NativeSectionWidget({
    super.key,
    required this.section,
    required this.selectedLanguage,
    required this.fontSizeMultiplier,
    required this.isContinuous,
    this.canonicalPageReference,
    this.scrollPhysics,
  });

  @override
  Widget build(BuildContext context) {
    final hasHindi = section.stanzas.any(
      (s) => s.hindiText != null && s.hindiText!.trim().isNotEmpty,
    );
    if (selectedLanguage == NativeLanguage.hindi && !hasHindi) {
      final widget = Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Text(
            'Preview not available',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

      return isContinuous
          ? widget
          : SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: widget,
              ),
            );
    }

    final isSindhi = selectedLanguage == NativeLanguage.sindhi;
    final isHindi = selectedLanguage == NativeLanguage.hindi;
    final heading = isSindhi
        ? section.headingSindhi
        : (isHindi && section.headingHindi != null)
        ? TextUtils.toDevanagariDigits(section.headingHindi!)
        : section.headingRoman;

    final baseFontSize = isSindhi ? 28.0 : (isHindi ? 24.0 : 20.0);
    final currentFontSize = baseFontSize * fontSizeMultiplier;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14.0, 20.0, 14.0, 64.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder(context), width: 1),
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              heading,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: isSindhi
                    ? AppTheme.sindhiHeadingFont
                    : AppTheme.serifFontFamily,
                fontSize: isSindhi
                    ? (currentFontSize * 1.2)
                    : (currentFontSize * 1.2),
                fontWeight: isSindhi ? FontWeight.w600 : FontWeight.bold,
                height: isSindhi ? 1.4 : null,
                color: isSindhi ? null : Theme.of(context).colorScheme.primary,
                foreground: isSindhi
                    ? (Paint()
                        ..color = Theme.of(context).colorScheme.primary
                        ..colorFilter = ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ))
                    : null,
                fontFeatures: isSindhi
                    ? const [FontFeature('COLR', 0), FontFeature('CPAL', 0)]
                    : null,
              ),
            ),
            if (isSindhi && section.subheadingSindhi != null) ...[
              const SizedBox(height: 12),
              Text(
                section.subheadingSindhi!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.sindhiHeadingFont,
                  fontSize: currentFontSize * 1.0,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: null,
                  foreground: Paint()
                    ..color = Theme.of(context).colorScheme.secondary
                    ..colorFilter = ColorFilter.mode(
                      Theme.of(context).colorScheme.secondary,
                      BlendMode.srcIn,
                    ),
                  fontFeatures: const [
                    FontFeature('COLR', 0),
                    FontFeature('CPAL', 0),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: SvgPicture.asset(
                'assets/images/divider.svg',
                width: 140,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ...section.stanzas.map((stanza) {
              if (isSindhi) {
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
              }

              String text = '';
              bool isRtl = false;
              TextAlign tAlign = TextAlign.left;

              if (isSindhi) {
                text = stanza.sindhiText;
                isRtl = true;
                tAlign = stanza.isCenteredBold
                    ? TextAlign.center
                    : TextAlign.right;
              } else if (isHindi && stanza.hindiText != null) {
                text = TextUtils.toDevanagariDigits(stanza.hindiText!);
                isRtl = false;
                tAlign = stanza.isCenteredBold
                    ? TextAlign.center
                    : TextAlign.left;
              } else {
                text = stanza.romanText;
                isRtl = false;
                tAlign = stanza.isCenteredBold
                    ? TextAlign.center
                    : TextAlign.left;
              }

              if (text.trim().isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stanza.stanzaNumber != null) ...[
                      Text(
                        '── ${isHindi ? TextUtils.toDevanagariDigits(stanza.stanzaNumber!.toString()) : stanza.stanzaNumber} ──',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: currentFontSize * 0.9,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildHighlightedText(
                      context,
                      text,
                      textAlign: tAlign,
                      textDirection: isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      defaultStyle: TextStyle(
                        fontFamily: isSindhi
                            ? AppTheme.sindhiRegularFont
                            : AppTheme.currentFontFamily,
                        fontSize: currentFontSize,
                        fontWeight: stanza.isCenteredBold
                            ? (isSindhi ? FontWeight.w600 : FontWeight.bold)
                            : FontWeight.normal,
                        height: isSindhi ? 1.4 : 1.5,
                        color: isSindhi
                            ? null
                            : (stanza.isCenteredBold
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface),
                        foreground: isSindhi
                            ? (Paint()
                                ..color = stanza.isCenteredBold
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface
                                ..colorFilter = ColorFilter.mode(
                                  stanza.isCenteredBold
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                  BlendMode.srcIn,
                                ))
                            : null,
                        fontFeatures: isSindhi
                            ? const [
                                FontFeature('COLR', 0),
                                FontFeature('CPAL', 0),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (section.trailingImagePath != null ||
                section.trailingDarkImagePath != null) ...[
              const SizedBox(height: 24),
              Center(
                child: Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final imgPath = isDark
                        ? (section.trailingDarkImagePath ??
                              section.trailingImagePath)
                        : (section.trailingImagePath ??
                              section.trailingDarkImagePath);
                    if (imgPath == null) return const SizedBox.shrink();
                    final hasDedicatedThemedImages =
                        section.trailingImagePath != null &&
                        section.trailingDarkImagePath != null;
                    return Image.asset(
                      imgPath,
                      height: 80,
                      fit: BoxFit.contain,
                      cacheHeight: 240,
                      color: hasDedicatedThemedImages
                          ? null
                          : (isDark
                                ? const Color(0xFFF5E6D3) // Ivory for dark mode
                                : const Color(
                                    0xFF4A2B2B,
                                  )), // Burgundy for light mode
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isContinuous) {
      return content;
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: scrollPhysics,
            child: Container(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              alignment: Alignment.center,
              child: content,
            ),
          );
        },
      );
    }
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text, {
    required TextStyle defaultStyle,
    required TextAlign textAlign,
    required TextDirection textDirection,
  }) {
    final Iterable<RegExpMatch> matches = _hariOmExp.allMatches(text);

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
            color: defaultStyle.foreground == null ? hariOmColor : null,
            foreground: defaultStyle.foreground != null
                ? (Paint()
                    ..color = hariOmColor
                    ..colorFilter = ColorFilter.mode(
                      hariOmColor,
                      BlendMode.srcIn,
                    ))
                : null,
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
