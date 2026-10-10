import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/satguru.dart';
import '../providers/satguru_provider.dart';
import 'satguru_biography_screen.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/frosted_app_bar.dart';

import 'package:html_unescape/html_unescape.dart';
import 'package:shimmer/shimmer.dart';

class SatgurusScreen extends ConsumerWidget {
  const SatgurusScreen({super.key});

  static const Map<String, String> _canonicalDates = {
    'satguru-baba-har-bhajan-sahib': '(1733–1853)',
    'satguru-baba-ram-bhajan-sahib': '(1853–1903)',
    'satguru-baba-roop-bhajan-sahib': '(1840–1924)',
    'satguru-baba-kishan-bhajan-sahib': '(1915–1929)',
    'satguru-baba-gobind-bhajan-sahib': '(1881–1951)',
    'satguru-baba-shiv-bhajan-sahib': '(1936–2008)',
    'satguru-baba-narayan-bhajan-sahib': '(1990–Present)',
  };

  String _getPatshahiLabel(int index) {
    switch (index) {
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
        return '${index + 1}th Patshahi';
    }
  }

  String _cleanExcerpt(String htmlString) {
    var unescape = HtmlUnescape();
    // Very simple HTML tag removal for excerpt
    String stripped = htmlString.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    return unescape.convert(stripped).trim();
  }

  String _getExcerpt(Satguru satguru) {
    if (satguru.excerpt.trim().isNotEmpty) {
      final cleaned = _cleanExcerpt(satguru.excerpt);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }
    switch (satguru.slug) {
      case 'satguru-baba-har-bhajan-sahib':
        return 'First Patshahi & Founder of Pooj Samadha Ashram, Shikarpur. Ignited the sacred Akhand Dhuni Sahib.';
      case 'satguru-baba-ram-bhajan-sahib':
        return 'Second Patshahi of Pooj Samadha Ashram. Embodiment of silent humility, deep meditation, and devotion.';
      case 'satguru-baba-roop-bhajan-sahib':
        return 'Third Patshahi of Pooj Samadha Ashram. Revered Yogiraj who expanded the sacred Darbar and Gufa Sahib.';
      case 'satguru-baba-kishan-bhajan-sahib':
        return 'Fourth Patshahi of Pooj Samadha Ashram. A beacon of divine grace, selflessness, and spiritual love.';
      case 'satguru-baba-gobind-bhajan-sahib':
        return 'Fifth Patshahi of Pooj Samadha Ashram. Steadfast guardian of the Ashram tradition and Amrit Vela.';
      case 'satguru-baba-shiv-bhajan-sahib':
        return 'Sixth Patshahi of Pooj Samadha Ashram. Rebuilt the sacred Dham, spreading divine blessings across the world.';
      case 'satguru-baba-narayan-bhajan-sahib':
        return 'Seventh Patshahi and present Gaddi Nasheen, carrying forward the divine lineage and spiritual wisdom.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satgurusAsync = ref.watch(satguruProvider);

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Satgurus Parampara'),
      body: satgurusAsync.when(
        data: (satgurus) {
          if (satgurus.isEmpty) {
            return const Center(child: Text('No Satguru data available.'));
          }

          final canonicalSlugs = [
            'satguru-baba-har-bhajan-sahib',
            'satguru-baba-ram-bhajan-sahib',
            'satguru-baba-roop-bhajan-sahib',
            'satguru-baba-kishan-bhajan-sahib',
            'satguru-baba-gobind-bhajan-sahib',
            'satguru-baba-shiv-bhajan-sahib',
            'satguru-baba-narayan-bhajan-sahib',
          ];

          final Map<String, Satguru> satguruBySlug = {
            for (var s in satgurus) s.slug: s,
          };

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
            itemCount: canonicalSlugs.length,
            itemBuilder: (context, index) {
              final slug = canonicalSlugs[index];
              final satguru = satguruBySlug[slug];
              if (satguru == null) return const SizedBox.shrink();
              final isPresent = index == 6; // 7th Patshahi
              final canonicalDate = _canonicalDates[slug] ?? '';
              final pLabel = _getPatshahiLabel(index);

              return Card(
                elevation: isPresent ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPresent
                        ? Theme.of(context).colorScheme.primary
                        : AppTheme.cardBorder(context),
                    width: isPresent ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SatguruBiographyScreen(
                          expectedSlug: slug,
                          patshahiLabel: pLabel,
                          index: index,
                          canonicalSlugs: canonicalSlugs,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Portrait with Hero transition & shimmer loader
                        Hero(
                          tag: 'satguru-image-$slug',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: satguru.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: satguru.imageUrl!,
                                    width: 86,
                                    height: 116,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    memCacheWidth: 200,
                                    memCacheHeight: 280,
                                    placeholder: (context, url) =>
                                        _buildShimmerImage(context),
                                    errorWidget: (context, url, error) =>
                                        _buildPlaceholder(context),
                                  )
                                : _buildPlaceholder(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Builder(
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
                              final dateMatches = RegExp(
                                r'\(([^)]*\d{4}[^)]*)\)',
                              ).allMatches(cleanTitle);
                              if (dateMatches.isNotEmpty) {
                                datesText = dateMatches.last.group(0) ?? '';
                                cleanTitle = cleanTitle
                                    .replaceFirst(datesText, '')
                                    .trim();
                                cleanTitle = cleanTitle.replaceAll(
                                  RegExp(r'^[,\-:\s]+|[,\-:\s]+$'),
                                  '',
                                );
                              }

                              // Fallback to canonical dates if not in title
                              if (datesText.isEmpty) {
                                datesText = canonicalDate;
                              }

                              final excerptText = _getExcerpt(satguru);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Above Title: Patshahi label + Present Satguru Badge
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      Text(
                                        TextUtils.preventOrphans(pLabel),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      if (isPresent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGold
                                                .withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryGold
                                                  .withValues(alpha: 0.4),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Present Satguru',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryGold,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Main Title: Satguru Name
                                  Text(
                                    TextUtils.preventOrphans(cleanTitle),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.serifFontFamily,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                    ),
                                  ),
                                  // Below Title: Date (Born - Death)
                                  if (datesText.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      datesText,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                  // Below Date: Curated summary / excerpt
                                  if (excerptText.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      excerptText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        height: 1.3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: isPresent
                              ? AppTheme.primaryGold
                              : Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: 7,
          itemBuilder: (context, index) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 150,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildShimmerImage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF38151D) : const Color(0xFFF0E5D8),
      highlightColor: isDark
          ? const Color(0xFF55222E)
          : const Color(0xFFFFF9F0),
      child: Container(
        width: 86,
        height: 116,
        color: isDark ? const Color(0xFF38151D) : const Color(0xFFF0E5D8),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 86,
      height: 116,
      color: isDark
          ? const Color(0xFF2E0E14)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.spa_rounded,
          size: 32,
          color: AppTheme.primaryGold.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
