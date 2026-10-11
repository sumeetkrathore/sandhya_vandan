import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/program.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../widgets/frosted_app_bar.dart';
import 'program_details_screen.dart';

enum ProgramFilter { all, ongoing, upcoming }

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final ProgramService _programService = ProgramService();
  late Future<List<Program>> _programsFuture;
  ProgramFilter _selectedFilter = ProgramFilter.all;

  @override
  void initState() {
    super.initState();
    _programsFuture = _programService.fetchUpcomingPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FrostedAppBar(title: 'Events & Programs'),
      body: FutureBuilder<List<Program>>(
        future: _programsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList(context);
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load events.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          final programs = snapshot.data;
          if (programs == null || programs.isEmpty) {
            return Center(
              child: Text(
                'No events or programs scheduled at the moment.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            );
          }

          final uniquePrograms = <Program>[];
          final seenIds = <int>{};
          for (final p in programs) {
            if (!seenIds.contains(p.id)) {
              seenIds.add(p.id);
              uniquePrograms.add(p);
            }
          }

          final ongoingCount = uniquePrograms.where((p) => p.isOngoing).length;
          final upcomingCount = uniquePrograms
              .where((p) => !p.isOngoing)
              .length;

          List<Program> displayedPrograms = uniquePrograms;
          if (_selectedFilter == ProgramFilter.ongoing) {
            displayedPrograms = uniquePrograms
                .where((p) => p.isOngoing)
                .toList();
          } else if (_selectedFilter == ProgramFilter.upcoming) {
            displayedPrograms = uniquePrograms
                .where((p) => !p.isOngoing)
                .toList();
          }

          return RefreshIndicator(
            color: AppTheme.primaryGold,
            onRefresh: () async {
              setState(() {
                _programsFuture = _programService.fetchUpcomingPrograms();
              });
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 32.0),
              children: [
                if (ongoingCount > 0 && upcomingCount > 0) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All (${uniquePrograms.length})',
                          ProgramFilter.all,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Ongoing ($ongoingCount)',
                          ProgramFilter.ongoing,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Upcoming ($upcomingCount)',
                          ProgramFilter.upcoming,
                        ),
                      ],
                    ),
                  ),
                ],
                if (displayedPrograms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        'No events in this category.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...displayedPrograms.map((p) => _buildEventCard(context, p)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ProgramFilter filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGold
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGold
                : AppTheme.cardBorder(context),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppTheme.darkBackground
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context) {
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
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Program program) {
    final hasImage = program.posters.isNotEmpty;
    final imageUrl = hasImage ? program.posters.first.url : null;

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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgramDetailsScreen(program: program),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null)
              Hero(
                tag: 'program_image_${program.id}',
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    memCacheHeight: 660,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Theme.of(context).brightness == Brightness.dark
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
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge (Happening Now / Upcoming)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: program.isOngoing
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                          : AppTheme.primaryGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
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
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 4,
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    program.title,
                    style: TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProgramDetailsScreen(program: program),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBurgundy,
                        foregroundColor: AppTheme.primaryIvory,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
