import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../models/program.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final Program program;

  const ProgramDetailsScreen({super.key, required this.program});

  void _shareEvent(String dateStr, String timeStr) {
    final String dateInfo = dateStr.isNotEmpty ? '\nDate: $dateStr' : '';
    final String locInfo = program.location.isNotEmpty
        ? '\nLocation: ${program.location}'
        : '';
    final String timeInfo = timeStr.isNotEmpty ? '\nTime: $timeStr' : '';
    final String linkInfo = program.url.isNotEmpty ? '\n${program.url}' : '';
    SharePlus.instance.share(
      ShareParams(
        text:
            '${program.title}$dateInfo$timeInfo$locInfo$linkInfo\n\nPooj Samadha Ashram, Shikarpur\nShared via Sandhya Vandan App',
        subject: program.title,
      ),
    );
  }

  Future<void> _launchMaps(String address) async {
    if (address.isEmpty) return;
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildIconRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime? startDate;
    DateTime? endDate;
    try {
      if (program.startDate.isNotEmpty) {
        startDate = DateTime.tryParse(program.startDate);
      }
      if (program.endDate.isNotEmpty) {
        endDate = DateTime.tryParse(program.endDate);
      }
    } catch (_) {}

    String dateStr = '';
    String timeStr = '';

    if (startDate != null) {
      if (endDate != null &&
          (startDate.year != endDate.year ||
              startDate.month != endDate.month ||
              startDate.day != endDate.day)) {
        if (startDate.month == endDate.month &&
            startDate.year == endDate.year) {
          dateStr =
              '${DateFormat('dd').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}';
        } else if (startDate.year == endDate.year) {
          dateStr =
              '${DateFormat('dd MMM').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}';
        } else {
          dateStr =
              '${DateFormat('dd MMM yyyy').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}';
        }
      } else {
        dateStr = DateFormat('dd MMM yyyy').format(startDate);
      }

      if (program.programTime.trim().isNotEmpty) {
        timeStr = program.programTime.trim();
      } else {
        final hasTime =
            startDate.hour != 0 ||
            startDate.minute != 0 ||
            (endDate != null && (endDate.hour != 0 || endDate.minute != 0));
        if (hasTime) {
          timeStr = DateFormat('h:mm a').format(startDate);
          if (endDate != null && (endDate.hour != 0 || endDate.minute != 0)) {
            timeStr += ' - ${DateFormat('h:mm a').format(endDate)}';
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          program.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Event',
              onPressed: () {
                final String dateInfo = dateStr.isNotEmpty
                    ? '\nDate: $dateStr'
                    : '';
                final String locInfo = program.location.isNotEmpty
                    ? '\nLocation: ${program.location}'
                    : '';
                final String timeInfo = timeStr.isNotEmpty
                    ? '\nTime: $timeStr'
                    : '';
                final String linkInfo = program.url.isNotEmpty
                    ? '\n${program.url}'
                    : '';
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${program.title}$dateInfo$timeInfo$locInfo$linkInfo\n\nPooj Samadha Ashram, Shikarpur\nShared via Sandhya Vandan App',
                    subject: program.title,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (program.posters.isNotEmpty)
              _ProgramPostersCarousel(program: program),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge (Happening Now / Upcoming)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: program.isOngoing
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                          : AppTheme.primaryGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: program.isOngoing
                            ? const Color(0xFF2E7D32)
                            : AppTheme.primaryGold.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (program.isOngoing) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          program.statusBadgeLabel,
                          style: TextStyle(
                            color: program.isOngoing
                                ? const Color(0xFF2E7D32)
                                : AppTheme.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    TextUtils.preventOrphans(program.title),
                    style: TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (dateStr.isNotEmpty)
                    _buildIconRow(
                      context,
                      Icons.calendar_today_rounded,
                      dateStr,
                    ),
                  if (timeStr.isNotEmpty)
                    _buildIconRow(context, Icons.access_time_rounded, timeStr),
                  if (program.location.isNotEmpty)
                    _buildIconRow(
                      context,
                      Icons.location_on_rounded,
                      program.location,
                    ),
                  if (program.address.isNotEmpty)
                    _buildIconRow(context, Icons.map_rounded, program.address),

                  if (program.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Divider(color: AppTheme.cardBorder(context), thickness: 1),
                    const SizedBox(height: 24),
                    Text(
                      'About this Event',
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: program.description,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        h3: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  if (program.address.isNotEmpty ||
                      program.location.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMaps(
                          program.address.isNotEmpty
                              ? program.address
                              : program.location,
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 20),
                        label: const Text('Get Directions on Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.darkBackground,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareEvent(dateStr, timeStr),
                      icon: const Icon(Icons.share_rounded, size: 19),
                      label: const Text('Share Event with Sangat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface,
                        side: BorderSide(color: AppTheme.cardBorder(context)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramPostersCarousel extends StatefulWidget {
  final Program program;
  const _ProgramPostersCarousel({required this.program});

  @override
  State<_ProgramPostersCarousel> createState() =>
      _ProgramPostersCarouselState();
}

class _ProgramPostersCarouselState extends State<_ProgramPostersCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.program.posters.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Hero(
          tag: 'program_image_${widget.program.id}',
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: widget.program.posters.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black87,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.program.posters[index].url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain, // Prevent cropping
                          memCacheWidth:
                              1000, // Memory optimization for Google Play
                          memCacheHeight: 1000,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A0A10)
                                : const Color(0xFFF3EBE1),
                            highlightColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF45151E)
                                : const Color(0xFFFAF6F0),
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.program.posters.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.program.posters.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
