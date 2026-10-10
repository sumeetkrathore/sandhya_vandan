import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'dart:async';

import '../models/program.dart';
import '../services/program_service.dart';
import '../screens/programs_screen.dart';
import '../screens/program_details_screen.dart';
import '../theme/app_theme.dart';

import 'package:shimmer/shimmer.dart';

class UpcomingEventsCarousel extends StatefulWidget {
  const UpcomingEventsCarousel({super.key});

  @override
  State<UpcomingEventsCarousel> createState() => _UpcomingEventsCarouselState();
}

class _UpcomingEventsCarouselState extends State<UpcomingEventsCarousel> {
  final ProgramService _programService = ProgramService();
  late Future<List<Program>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _programsFuture = _programService.fetchUpcomingPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Program>>(
      future: _programsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upcoming Events",
                style: AppTheme.sectionTitleMain.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.primaryIvory
                      : AppTheme.deepBurgundy,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Shimmer.fromColors(
                        baseColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        highlightColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          // Gracefully handle error or empty state by showing nothing
          return const SizedBox.shrink();
        }

        // Filter out duplicate program IDs to prevent Hero tag crashes
        final uniquePrograms = <Program>[];
        final seenIds = <int>{};
        for (final p in snapshot.data!) {
          if (!seenIds.contains(p.id)) {
            seenIds.add(p.id);
            uniquePrograms.add(p);
          }
        }

        if (uniquePrograms.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Events & Programs",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sectionTitleMain.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryIvory
                          : AppTheme.deepBurgundy,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgramsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "View All",
                          style: TextStyle(
                            fontFamily: AppTheme.currentFontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppTheme.primaryGold,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420, // Tall 3:4 portrait height for posters
              child: PageView.builder(
                controller: PageController(
                  viewportFraction: 0.9,
                ), // Shows a peek of the next card
                itemCount: uniquePrograms.length,
                itemBuilder: (context, index) {
                  final program = uniquePrograms[index];
                  final hasImage = program.posters.isNotEmpty;
                  final imageUrl = hasImage ? program.posters.first.url : null;
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final borderColor = AppTheme.cardBorder(context);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProgramDetailsScreen(program: program),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'program_image_${program.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: imageUrl != null
                                ? Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color: Colors.black87, // Dark background for letterboxing
                                        child: Builder(
                                          builder: (context) {
                                            try {
                                              // Handle potential empty URLs that cause synchronous ArgumentError
                                              if (imageUrl.trim().isEmpty) {
                                                return _buildFallback(context);
                                              }

                                              return CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.contain, // Prevent cropping
                                                memCacheWidth: 1000,
                                                errorWidget:
                                                    (context, url, error) {
                                                      return _buildFallback(
                                                        context,
                                                      );
                                                    },
                                              );
                                            } catch (e) {
                                              return _buildFallback(context);
                                            }
                                          },
                                        ),
                                      ),
                                      // Status Badge (Happening Now / Upcoming)
                                      Positioned(
                                        top: 14,
                                        left: 14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: program.isOngoing
                                                ? const Color(0xFF2E7D32)
                                                : AppTheme.secondarySaffron,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (program.isOngoing) ...[
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                                const SizedBox(width: 5),
                                              ],
                                              Text(
                                                program.statusBadgeLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Title and tap visual cue
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 0.9,
                                                ),
                                              ],
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                program.title,
                                                style: const TextStyle(
                                                  fontFamily: AppTheme.serifFontFamily,
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black54,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: const [
                                                  Text(
                                                    "Tap to view details",
                                                    style: TextStyle(
                                                      fontFamily: AppTheme.currentFontFamily,
                                                      color: AppTheme.primaryGold,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(
                                                    Icons.touch_app,
                                                    size: 14,
                                                    color: AppTheme.primaryGold,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildFallback(context),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.event,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 48,
        ),
      ),
    );
  }
}
