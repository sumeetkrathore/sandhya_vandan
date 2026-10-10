import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shimmer/shimmer.dart';

import '../models/satguru.dart';
import '../providers/satguru_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

class SatguruBiographyScreen extends ConsumerWidget {
  final String expectedSlug;
  final String patshahiLabel;
  final int index;
  final List<String> canonicalSlugs;

  const SatguruBiographyScreen({
    super.key,
    required this.expectedSlug,
    required this.patshahiLabel,
    required this.index,
    required this.canonicalSlugs,
  });

  void _showTextSizeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text Size', style: AppTheme.sheetTitle),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final settings = ref.watch(settingsProvider);
                    final settingsNotifier = ref.read(
                      settingsProvider.notifier,
                    );
                    return Row(
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
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satguruAsync = ref.watch(satguruBiographyProvider(expectedSlug));
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: satguruAsync.when(
          data: (satguru) {
            final guruName = TextUtils.cleanSatguruName(satguru.title);
            return Text(
              guruName,
              style: AppTheme.appBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          loading: () => const Text('Biography', style: AppTheme.cardTitleMain),
          error: (err, _) =>
              const Text('Biography', style: AppTheme.cardTitleMain),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: IconButton(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: 'Text Size',
              onPressed: () => _showTextSizeOptions(context),
            ),
          ),
        ],
      ),
      body: satguruAsync.when(
        data: (satguru) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (satguru.imageUrl != null)
                Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.primaryGold.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.25,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.4
                                : 0.12,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'satguru-image-$expectedSlug',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: satguru.imageUrl!,
                          width: double.infinity,
                          height: 480,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          memCacheWidth: 900,
                          placeholder: (context, url) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return Shimmer.fromColors(
                              baseColor: isDark
                                  ? const Color(0xFF38151D)
                                  : const Color(0xFFF0E5D8),
                              highlightColor: isDark
                                  ? const Color(0xFF55222E)
                                  : const Color(0xFFFFF9F0),
                              child: Container(
                                width: double.infinity,
                                height: 480,
                                color: isDark
                                    ? const Color(0xFF38151D)
                                    : const Color(0xFFF0E5D8),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) => Container(
                            height: 480,
                            color: Theme.of(context).cardColor,
                            child: Center(
                              child: Icon(
                                Icons.spa_rounded,
                                size: 64,
                                color: AppTheme.primaryGold.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  String cleanTitle = satguru.title.trim();
                  String datesText = '';

                  // Strip duplicate patshahiLabel from title using robust regex
                  cleanTitle = cleanTitle
                      .replaceFirst(
                        RegExp(
                          r'^(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|\d+st|\d+nd|\d+rd|\d+th)\s+(?:patshahi|light|gaddi nasheen|gadi nasheen)\s*(?:[:\-]|&#8211;|&#8212;)*\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();

                  // Extract dates robustly from anywhere in the title
                  final dateMatches = RegExp(r'\(([^)]*\d{4}[^)]*)\)')
                      .allMatches(cleanTitle);
                  if (dateMatches.isNotEmpty) {
                    datesText = dateMatches.last.group(0) ?? '';
                    cleanTitle = cleanTitle.replaceFirst(datesText, '').trim();
                    cleanTitle = cleanTitle.replaceAll(
                      RegExp(r'^[,\-:\s]+|[,\-:\s]+$'),
                      '',
                    );
                  }

                  // Fallback to canonical dates if not in title
                  if (datesText.isEmpty) {
                    datesText = _canonicalDates[expectedSlug] ?? '';
                  }

                  // Clean patshahiLabel so it only contains the patshahi text
                  String cleanPatshahi = patshahiLabel
                      .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
                      .trim();

                  return Column(
                    children: [
                      // ABOVE TITLE: Patshahi Number
                      Text(
                        TextUtils.preventOrphans(cleanPatshahi),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5 * settings.fontSizeMultiplier,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // MAIN TITLE: Satguru Name
                      Text(
                        TextUtils.balanceCenteredLines(
                          cleanTitle,
                          singleLineThreshold: 20,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontSize: 26.0 * settings.fontSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      // BELOW TITLE: Born - Death date
                      if (datesText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          datesText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5 * settings.fontSizeMultiplier,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                      // Sacred golden lotus divider flourish
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppTheme.primaryGold.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.spa_rounded,
                              size: 15,
                              color: AppTheme.primaryGold.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryGold.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Html(
                data: _sanitizeHtml(satguru, satguru.content, satguru.imageUrl),
                style: {
                  "body": Style(
                    fontFamily: AppTheme.currentFontFamily,
                    fontSize: FontSize(17.0 * settings.fontSizeMultiplier),
                    lineHeight: const LineHeight(1.6),
                    color: Theme.of(context).colorScheme.onSurface,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "p": Style(
                    fontFamily: AppTheme.currentFontFamily,
                    margin: Margins.only(bottom: 16.0),
                  ),
                  "h1": Style(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: FontSize(26.0 * settings.fontSizeMultiplier),
                    fontWeight: FontWeight.bold,
                    margin: Margins.only(top: 24.0, bottom: 12.0),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  "h2": Style(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: FontSize(24.0 * settings.fontSizeMultiplier),
                    fontWeight: FontWeight.bold,
                    margin: Margins.only(top: 24.0, bottom: 12.0),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  "h3": Style(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: FontSize(22.0 * settings.fontSizeMultiplier),
                    fontWeight: FontWeight.bold,
                    margin: Margins.only(top: 20.0, bottom: 10.0),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  "h4": Style(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: FontSize(20.0 * settings.fontSizeMultiplier),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  "h5": Style(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: FontSize(18.0 * settings.fontSizeMultiplier),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  "h6": Style(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: FontSize(16.0 * settings.fontSizeMultiplier),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                },
              ),
              const SizedBox(height: 32),
              _buildNavigation(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading biography: $err')),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (index > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final prevSlug = canonicalSlugs[index - 1];
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SatguruBiographyScreen(
                      expectedSlug: prevSlug,
                      patshahiLabel: _getPatshahiLabel(index - 1),
                      index: index - 1,
                      canonicalSlugs: canonicalSlugs,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Previous', textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 16),
        if (index < canonicalSlugs.length - 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final nextSlug = canonicalSlugs[index + 1];
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SatguruBiographyScreen(
                      expectedSlug: nextSlug,
                      patshahiLabel: _getPatshahiLabel(index + 1),
                      index: index + 1,
                      canonicalSlugs: canonicalSlugs,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text('Next', textAlign: TextAlign.center)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          )
        else
          const Spacer(),
      ],
    );
  }

  static final Map<String, String> _sanitizedHtmlCache = {};

  String _sanitizeHtml(Satguru satguru, String rawHtml, String? heroImageUrl) {
    final cacheKey = '${satguru.slug}_${rawHtml.hashCode}';
    if (_sanitizedHtmlCache.containsKey(cacheKey)) {
      return _sanitizedHtmlCache[cacheKey]!;
    }

    // 1. Safely chop the footer from the raw HTML string
    final lower = rawHtml.toLowerCase();

    int footerIndex = lower.lastIndexOf('seven masters, one eternal light');

    // If 'seven masters' is not found (e.g., older cached HTML), look for 'the sacred lineage'
    // but ONLY if it appears in the bottom half of the document to protect valid top headings.
    if (footerIndex == -1) {
      final lineageMatches = RegExp(
        r'the\s+sacred\s+lineage',
        caseSensitive: false,
      ).allMatches(lower);
      if (lineageMatches.isNotEmpty) {
        final lastMatch = lineageMatches.last;
        if (lastMatch.start > lower.length / 2) {
          footerIndex = lastMatch.start;
        }
      }
    }

    if (footerIndex != -1) {
      int cutIndex = footerIndex;

      // Elementor injects a massive amount of wrapper divs between the heading and the paragraph.
      // E.g. </div></div><div class="..."><div class="...">
      final lineageIndex = lower.lastIndexOf('the sacred lineage', footerIndex);

      // If found in the bottom half of the document, just cut from there.
      if (lineageIndex != -1 && lineageIndex > lower.length / 2) {
        cutIndex = lineageIndex;
      } else if (lineageIndex != -1 && (footerIndex - lineageIndex) < 2000) {
        // Fallback: if it's within 2000 chars of the footer (to account for Elementor bloat)
        cutIndex = lineageIndex;
      }

      final tagStart = rawHtml.lastIndexOf('<', cutIndex);
      if (tagStart != -1 && (cutIndex - tagStart) < 500) {
        cutIndex = tagStart;
      }
      rawHtml = rawHtml.substring(0, cutIndex);
    }

    final document = html_parser.parse(rawHtml);

    // 2. Remove unwanted tags and elementor artifacts
    final unwantedSelectors = [
      'script',
      'iframe',
      'style',
      'form',
      'object',
      'embed',
      'svg',
      'img', // Remove inline images from biography for cleaner mobile reading
      '.elementor-background-overlay',
      '.elementor-widget-table-of-contents',
      '#ez-toc-container',
      '.toc_container',
    ];
    for (var selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((el) => el.remove());
    }

    // 2.2 Remove "On this page" blocks if they weren't caught by the selectors above
    for (var el in document.querySelectorAll(
      'h2, h3, h4, h5, h6, p, span, div',
    )) {
      final text = el.text.toLowerCase().trim();
      if (text.contains('on this page') && text.length < 50) {
        var p = el.parent;
        bool removed = false;
        while (p != null && p.localName != 'body') {
          final classes = p.classes.join(' ').toLowerCase();
          if (classes.contains('widget') ||
              classes.contains('toc') ||
              classes.contains('section')) {
            p.remove();
            removed = true;
            break;
          }
          p = p.parent;
        }
        if (!removed) {
          // Remove the list if it's the immediate next sibling
          var next = el.nextElementSibling;
          if (next != null &&
              (next.localName == 'ul' || next.localName == 'ol')) {
            next.remove();
          }
          // Or if the heading is wrapped in a div, check the div's next sibling
          var parentNode = el.parent;
          if (parentNode != null && parentNode.localName != 'body') {
            var parentNext = parentNode.nextElementSibling;
            if (parentNext != null &&
                (parentNext.localName == 'ul' ||
                    parentNext.localName == 'ol')) {
              parentNext.remove();
            }
          }
          el.remove();
        }
      }
    }

    // 2.5 Remove duplicate H1 heading if it exactly matches the title
    final firstH1 = document.querySelector('h1');
    if (firstH1 != null) {
      final h1Text = firstH1.text.trim();
      final titleText = satguru.title.trim();
      if (h1Text == titleText || h1Text == 'Satguru $titleText') {
        firstH1.remove();
      }
    }

    // 2.6 Remove repetitive intro headings that duplicate Flutter's native header
    // e.g. "<p>The First Light (1733–1853)</p>" or "<h2>The First Patshahi: Satguru Baba...</h2>"
    final introHeadings = document.querySelectorAll('h1, h2, h3, h4, p');
    for (var el in introHeadings.take(8)) {
      final text = el.text.trim();
      final isRedundantIntro = RegExp(
        r'^\s*the\s+(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|\d+st|\d+nd|\d+rd|\d+th)\s+(?:light|patshahi|gaddi nasheen|gadi nasheen)',
        caseSensitive: false,
      ).hasMatch(text);
      if (isRedundantIntro && text.length < 120) {
        el.remove();
      }
    }

    // 3. (Hero Image removal is no longer needed since we remove all images)

    // 4. Remove empty elementor sections that cause large blank gaps
    document
        .querySelectorAll('.elementor-section, .elementor-widget-wrap')
        .forEach((el) {
          if (el.children.isEmpty && el.text.trim().isEmpty) {
            el.remove();
          }
        });

    // 5. Strip inline styles and color classes to ensure theme adaptation
    // Do this LAST so that we don't break our own class-based elementor cleanup above.
    document.querySelectorAll('*').forEach((el) {
      el.attributes.remove('style');
      el.attributes.remove('class');
    });

    final result = document.body?.innerHtml ?? rawHtml;
    _sanitizedHtmlCache[cacheKey] = result;
    return result;
  }

  static const Map<String, String> _canonicalDates = {
    'satguru-baba-har-bhajan-sahib': '(1733–1853)',
    'satguru-baba-ram-bhajan-sahib': '(1853–1903)',
    'satguru-baba-roop-bhajan-sahib': '(1840–1924)',
    'satguru-baba-kishan-bhajan-sahib': '(1915–1929)',
    'satguru-baba-gobind-bhajan-sahib': '(1881–1951)',
    'satguru-baba-shiv-bhajan-sahib': '(1936–2008)',
    'satguru-baba-narayan-bhajan-sahib': '(1990–Present)',
  };

  String _getPatshahiLabel(int idx) {
    switch (idx) {
      case 0:
        return '1st Patshahi';
      case 1:
        return '2nd Patshahi';
      case 2:
        return '3rd Patshahi';
      case 3:
        return '4th Patshahi';
      case 4:
        return '5th Patshahi';
      case 5:
        return '6th Patshahi';
      case 6:
        return '7th Patshahi';
      default:
        return '${idx + 1}th Patshahi';
    }
  }
}
