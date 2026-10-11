import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/tipno_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tipno_share_dialog.dart';
import '../widgets/frosted_app_bar.dart';

class TipnoScreen extends ConsumerWidget {
  const TipnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipnoState = ref.watch(tipnoProvider);

    return Scaffold(
      appBar: FrostedAppBar(
        title: 'Monthly Tipno',
        actions: [
          tipnoState.maybeWhen(
            data: (tipno) {
              if (tipno == null) return const SizedBox.shrink();
              final events = _parseTipnoEvents(tipno.content);
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share Tipno',
                  onPressed: () {
                    TipnoShareDialog.show(
                      context,
                      title: tipno.title,
                      events: events,
                    );
                  },
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: tipnoState.when(
        data: (tipno) {
          if (tipno == null) {
            return const Center(child: Text('No Tipno available.'));
          }

          final events = _parseTipnoEvents(tipno.content);

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(tipnoProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length + 1, // +1 for the header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (tipno.title.isNotEmpty)
                          Text(
                            tipno.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.serifFontFamily,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 18,
                          ),
                          label: const Text('Download Yearly Tipno'),
                          onPressed: () async {
                            const urlStr =
                                'https://jaisamadha.com/wp-content/uploads/2026/08/Dharmic-Tipno-2026-27.jpg';
                            final uri = Uri.parse(urlStr);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.inAppBrowserView,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGold,
                            side: BorderSide(
                              color: AppTheme.primaryGold.withValues(
                                alpha: 0.6,
                              ),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final event = events[index - 1];
                final isAshram = _isAshramEvent(event['name'] ?? '');
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    elevation: isAshram ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isAshram
                            ? AppTheme.primaryGold
                            : AppTheme.cardBorder(context),
                        width: isAshram ? 1.6 : 1.0,
                      ),
                    ),
                    color: isAshram
                        ? (isDark
                              ? AppTheme.primaryGold.withValues(alpha: 0.12)
                              : const Color(0xFFFFFDF5))
                        : Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isAshram
                          ? () {
                              TipnoShareDialog.show(
                                context,
                                title: tipno.title,
                                events: events,
                                singleEvent: event,
                              );
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if ((event['date'] ?? '').isNotEmpty) ...[
                              Builder(
                                builder: (context) {
                                  String rawDate = (event['date'] ?? '').trim();
                                  String datePart = rawDate;
                                  String monthPart = '';

                                  if (rawDate.contains(' ')) {
                                    List<String> parts = rawDate.split(' ');
                                    if (parts.length >= 2) {
                                      monthPart = parts.last.toUpperCase();
                                      datePart = parts
                                          .sublist(0, parts.length - 1)
                                          .join(' ');
                                    }
                                  }

                                  return Container(
                                    width: 58,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 2,
                                    ),
                                    decoration: isAshram
                                        ? BoxDecoration(
                                            color: AppTheme.primaryGold
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryGold
                                                  .withValues(alpha: 0.25),
                                              width: 1,
                                            ),
                                          )
                                        : null,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          datePart,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: AppTheme.primaryGold,
                                                fontWeight: FontWeight.w900,
                                                height: 1.0,
                                              ),
                                        ),
                                        if (monthPart.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            monthPart,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: AppTheme.primaryGold
                                                      .withValues(alpha: 0.8),
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 1.5,
                                height: isAshram ? 44 : 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withValues(
                                    alpha: isAshram ? 0.6 : 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      event['name'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: isAshram
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 16.5,
                                            height: 1.3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => _buildShimmerLoader(context),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading Tipno:\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF2A0A10)
        : const Color(0xFFF3EBE1);
    final highlightColor = isDark
        ? const Color(0xFF45151E)
        : const Color(0xFFFAF6F0);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isAshramEvent(String name) {
    final lower = name.toLowerCase();

    return lower.contains('green sunday') ||
        lower.contains('greensunday') ||
        lower.contains('گرين سنڊي') ||
        lower.contains('ग्रीन संडे') ||
        lower.contains('varsi') ||
        lower.contains('warsi') ||
        lower.contains('varsee') ||
        lower.contains('warsee') ||
        lower.contains('वर्सी') ||
        lower.contains('वारसी') ||
        lower.contains('वरसी') ||
        lower.contains('ورسي') ||
        lower.contains('janam utsaw') ||
        lower.contains('janam utsav') ||
        lower.contains('janm utsav') ||
        lower.contains('janm utsaw') ||
        lower.contains('janam diwas') ||
        lower.contains('janam divas') ||
        lower.contains('जन्मोत्सव') ||
        lower.contains('जन्म उत्सव') ||
        lower.contains('जन्म दिवस') ||
        lower.contains('جنم اتسو') ||
        lower.contains('جنم ڏينهن') ||
        lower.contains('samadha') ||
        lower.contains('ashram') ||
        lower.contains('aashram') ||
        lower.contains('patshahi') ||
        lower.contains('پاتشاهي') ||
        lower.contains('पातशाही') ||
        lower.contains('saikadasa') ||
        lower.contains('shikarpur');
  }

  List<Map<String, String>> _parseTipnoEvents(String content) {
    final lines = content.split('\n');
    final events = <Map<String, String>>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        final name = parts[0].trim();
        final date = parts.sublist(1).join(':').trim();
        events.add({'name': name, 'date': date});
      } else {
        events.add({'name': trimmed, 'date': ''});
      }
    }

    return events;
  }
}
