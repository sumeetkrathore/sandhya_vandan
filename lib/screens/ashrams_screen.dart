import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/ashrams_provider.dart';
import '../models/ashram.dart';
import '../theme/app_theme.dart';
import '../widgets/frosted_app_bar.dart';

import 'package:html/parser.dart' as html_parser;

class AshramsScreen extends ConsumerStatefulWidget {
  const AshramsScreen({super.key});

  @override
  ConsumerState<AshramsScreen> createState() => _AshramsScreenState();
}

class _AshramsScreenState extends ConsumerState<AshramsScreen> {
  // India taxonomy ID = 175, Pakistan taxonomy ID = 176
  static const int indiaId = 175;
  static const int pakistanId = 176;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Ashram> _filterAshrams(List<Ashram> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((a) {
      final titleMatch = a.title.toLowerCase().contains(q);
      final addressMatch = a.address?.toLowerCase().contains(q) ?? false;
      final phoneMatch = a.phone?.contains(q) ?? false;
      final contentMatch = a.content.toLowerCase().contains(q);
      return titleMatch || addressMatch || phoneMatch || contentMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get device country code
    final countryCode =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    final isIndia = countryCode == 'IN';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: FrostedAppBar(
          title: _isSearching ? null : 'Our Ashrams',
          centerTitle: !_isSearching,
          titleWidget: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search ashram by city or name...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                )
              : null,
          actions: [
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear search',
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search ashrams',
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: AppTheme.primaryGold,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppTheme.darkBackground,
                  unselectedLabelColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    const Tab(text: 'All'),
                    if (isIndia) const Tab(text: 'India'),
                    const Tab(text: 'Pakistan'),
                    if (!isIndia) const Tab(text: 'India'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ref
                  .watch(ashramsProvider)
                  .when(
                    data: (ashrams) {
                      final indiaAshrams = ashrams
                          .where((a) => a.countryIds.contains(indiaId))
                          .toList();
                      final pakistanAshrams = ashrams
                          .where((a) => a.countryIds.contains(pakistanId))
                          .toList();

                      // Sort 'All' list based on locale
                      final allAshrams = List<Ashram>.from(ashrams);
                      allAshrams.sort((a, b) {
                        final aIsIndia = a.countryIds.contains(indiaId);
                        final bIsIndia = b.countryIds.contains(indiaId);
                        final aIsPak = a.countryIds.contains(pakistanId);
                        final bIsPak = b.countryIds.contains(pakistanId);

                        if (isIndia) {
                          // IN users: India first, then Pakistan
                          if (aIsIndia && !bIsIndia) return -1;
                          if (!aIsIndia && bIsIndia) return 1;
                          if (aIsPak && !bIsPak) return -1;
                          if (!aIsPak && bIsPak) return 1;
                        } else {
                          // PK and rest of world: Pakistan first, then India
                          if (aIsPak && !bIsPak) return -1;
                          if (!aIsPak && bIsPak) return 1;
                          if (aIsIndia && !bIsIndia) return -1;
                          if (!aIsIndia && bIsIndia) return 1;
                        }
                        return 0;
                      });

                      return RefreshIndicator(
                        color: AppTheme.primaryGold,
                        onRefresh: () async {
                          ref.invalidate(ashramsProvider);
                          await ref
                              .read(ashramsProvider.future)
                              .catchError((_) => <Ashram>[]);
                        },
                        child: TabBarView(
                          children: [
                            _buildAshramList(
                              _filterAshrams(allAshrams),
                              showCountryTag: true,
                            ),
                            if (isIndia)
                              _buildAshramList(
                                _filterAshrams(indiaAshrams),
                                showCountryTag: false,
                              ),
                            _buildAshramList(
                              _filterAshrams(pakistanAshrams),
                              showCountryTag: false,
                            ),
                            if (!isIndia)
                              _buildAshramList(
                                _filterAshrams(indiaAshrams),
                                showCountryTag: false,
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => _buildShimmerLoader(context),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.temple_hindu_rounded,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to Load Ashrams',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your connection and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () => ref.invalidate(ashramsProvider),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Try Again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGold,
                                side: const BorderSide(
                                  color: AppTheme.primaryGold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF38151D) : const Color(0xFFF0E5D8),
          highlightColor: isDark
              ? const Color(0xFF55222E)
              : const Color(0xFFFFF9F0),
          child: Container(
            height: 220,
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAshramList(List<Ashram> ashrams, {bool showCountryTag = false}) {
    if (ashrams.isEmpty) {
      return const Center(child: Text('No ashrams found for this region.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: ashrams.length,
      itemBuilder: (context, index) {
        final ashram = ashrams[index];
        return _buildAshramCard(ashram, showCountryTag: showCountryTag);
      },
    );
  }

  String _formatPhoneDisplay(String rawPhone) {
    final trimmed = rawPhone.trim();
    if (trimmed.length == 11 && trimmed.startsWith('03')) {
      return '${trimmed.substring(0, 4)} ${trimmed.substring(4)}';
    }
    return trimmed;
  }

  Widget _buildAshramCard(Ashram ashram, {bool showCountryTag = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsedTitle =
        html_parser.parse(ashram.title).documentElement?.text ?? ashram.title;

    final formattedPhone = ashram.hasPhone
        ? _formatPhoneDisplay(ashram.phone!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.elevatedBurgundy : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.cardBorderDark : AppTheme.cardBorderLight,
          width: 1.0,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final urlStr = ashram.link ?? 'https://jaisamadha.com/ashrams';
              final url = Uri.parse(urlStr);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.inAppBrowserView);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------------------------------
                // ASHRAM IMAGE BANNER WITH COUNTRY BADGE
                // -----------------------------------------------------------
                Stack(
                  children: [
                    if (ashram.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: ashram.imageUrl!,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        memCacheHeight: 400,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: isDark
                              ? const Color(0xFF38151D)
                              : const Color(0xFFF0E5D8),
                          highlightColor: isDark
                              ? const Color(0xFF55222E)
                              : const Color(0xFFFFF9F0),
                          child: Container(
                            height: 190,
                            color: isDark
                                ? const Color(0xFF38151D)
                                : const Color(0xFFF0E5D8),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 150,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Icon(
                            Icons.temple_hindu_rounded,
                            size: 56,
                            color: AppTheme.primaryGold.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        color: AppTheme.primaryGold.withValues(alpha: 0.08),
                        child: Icon(
                          Icons.temple_hindu_rounded,
                          size: 48,
                          color: AppTheme.primaryGold.withValues(alpha: 0.5),
                        ),
                      ),
                    if (showCountryTag &&
                        (ashram.countryIds.contains(indiaId) ||
                            ashram.countryIds.contains(pakistanId)))
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.deepBurgundy.withValues(
                              alpha: 0.88,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryGold.withValues(
                                alpha: 0.5,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            ashram.countryIds.contains(indiaId)
                                ? 'India'
                                : 'Pakistan',
                            style: const TextStyle(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // -----------------------------------------------------------
                // ASHRAM CARD CONTENT & CONTACT DETAILS
                // -----------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parsedTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 17.5,
                          height: 1.25,
                          color: isDark
                              ? AppTheme.primaryIvory
                              : AppTheme.textPrimaryDark,
                        ),
                      ),

                      // Address Display
                      if (ashram.address != null &&
                          ashram.address!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: AppTheme.primaryGold,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ashram.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Phone Contact Display (Clean formatted text line)
                      if (formattedPhone != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 15,
                              color: AppTheme.primaryGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedPhone,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: isDark
                                    ? AppTheme.primaryGold
                                    : AppTheme.secondaryMaroon,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // -----------------------------------------------------------
                      // ACTION BUTTONS (Call & Directions)
                      // -----------------------------------------------------------
                      if (ashram.hasPhone || ashram.hasMapUrl) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (ashram.hasPhone) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final telUri = Uri.parse(
                                      'tel:${ashram.phone}',
                                    );
                                    if (await canLaunchUrl(telUri)) {
                                      await launchUrl(telUri);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.phone_in_talk_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Call',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryGold,
                                    side: BorderSide(
                                      color: AppTheme.primaryGold.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              if (ashram.hasMapUrl) const SizedBox(width: 10),
                            ],
                            if (ashram.hasMapUrl) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final mapUri = Uri.parse(ashram.mapUrl!);
                                    if (await canLaunchUrl(mapUri)) {
                                      await launchUrl(
                                        mapUri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.near_me_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Directions',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: AppTheme.darkBackground,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
