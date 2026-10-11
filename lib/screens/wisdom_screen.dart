import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../widgets/download_button.dart';
import 'youtube_video_screen.dart';
import '../repositories/audio_repository.dart';
import '../models/audio_item.dart';
import '../providers/settings_provider.dart';
import 'audio_player_screen.dart';

enum WisdomTab { audio, videos }

class WisdomScreen extends ConsumerStatefulWidget {
  final WisdomTab initialTab;

  const WisdomScreen({super.key, this.initialTab = WisdomTab.audio});

  @override
  ConsumerState<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends ConsumerState<WisdomScreen> {

  String? _selectedTag;
  late WisdomTab _selectedTab;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPlayerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const AudioPlayerScreen(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final title = _selectedTab == WisdomTab.audio
        ? 'Audio Coming Soon'
        : 'Videos Coming Soon';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(
              _selectedTab == WisdomTab.videos
                  ? Icons.smart_display_rounded
                  : Icons.library_music_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTab == WisdomTab.videos
                  ? 'Satsang and discourse videos will appear here.'
                  : 'Dynamic tracks will appear here once uploaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(audioGroupedProvider);
                ref.invalidate(videosProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check for Updates'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGold,
                side: const BorderSide(color: AppTheme.primaryGold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wisdom Hub', style: AppTheme.appBarTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGold,
          onRefresh: () async {
            ref.invalidate(audioGroupedProvider);
            ref.invalidate(videosProvider);
            await Future.wait([
              ref
                  .read(audioGroupedProvider.future)
                  .catchError((_) => <String, List<AudioItem>>{}),
              ref.read(videosProvider.future).catchError((_) => <AudioItem>[]),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -----------------------------------------
                // SEARCH BAR (Matching Proposal Layout)
                // -----------------------------------------
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF260D12)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.cardBorder(context),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.2
                              : 0.04,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search bhajans, satsangs...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryGold,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Clear search',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // -----------------------------------------
                // SANDHYA VANDAN PRIMARY CARD
                // -----------------------------------------
                GestureDetector(
                  onTap: () {
                    final audioState = ref.read(audioProvider);
                    final audioNotifier = ref.read(audioProvider.notifier);

                    final isSandhyaActive =
                        audioState.currentAudioItem == null &&
                        !audioState.activeAudioSectionId.startsWith('item_');

                    if (!isSandhyaActive || !audioState.isLoaded) {
                      audioNotifier.playSandhyaVandan(autoPlay: true);
                    } else if (!audioState.isPlaying) {
                      audioNotifier.play();
                    }

                    _openPlayerSheet(context, ref);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2A1115), // Deep rich burgundy
                          Color(0xFF4A181F), // Royal maroon
                          Color(0xFF331418), // Deep grounding base
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.22),
                          blurRadius: 24,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.primaryGold.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sandhya Vandan',
                                style: TextStyle(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFAF6F0),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Listen to complete Sandhya Vandan Nem',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryGold.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (ref.watch(audioProvider).isPlaying &&
                                  ref.watch(audioProvider).currentAudioItem ==
                                      null &&
                                  !ref
                                      .watch(audioProvider)
                                      .activeAudioSectionId
                                      .startsWith('item_')) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryGold.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SoundWaveBars(
                                        color: AppTheme.primaryGold,
                                        isPlaying: true,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Playing',
                                        style: TextStyle(
                                          color: AppTheme.primaryGold,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Side: Download Button (Green Tick when downloaded) + Golden Play Button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: DownloadButton(
                                  url: ref
                                      .read(audioProvider.notifier)
                                      .mainSandhyaVandanUrl,
                                  iconColor: AppTheme.primaryGold,
                                  showText: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Double-Ring Golden Halo Play Button
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                final audioState = ref.read(audioProvider);
                                final audioNotifier = ref.read(
                                  audioProvider.notifier,
                                );

                                final isSandhyaActive =
                                    audioState.currentAudioItem == null &&
                                    !audioState.activeAudioSectionId.startsWith(
                                      'item_',
                                    );

                                final autoPlay = ref
                                    .read(settingsProvider)
                                    .autoPlayAudio;
                                if (!isSandhyaActive || !audioState.isLoaded) {
                                  audioNotifier.playSandhyaVandan(
                                    autoPlay: autoPlay,
                                  );
                                } else if (autoPlay && !audioState.isPlaying) {
                                  audioNotifier.play();
                                }

                                _openPlayerSheet(context, ref);
                              },
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.primaryGold.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF5D77F),
                                          AppTheme.primaryGold,
                                          Color(0xFFC88A24),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryGold
                                              .withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      ref.watch(audioProvider).isPlaying &&
                                              ref
                                                      .watch(audioProvider)
                                                      .currentAudioItem ==
                                                  null &&
                                              !ref
                                                  .watch(audioProvider)
                                                  .activeAudioSectionId
                                                  .startsWith('item_')
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppTheme.darkBackground,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // -----------------------------------------
                // AUDIO & VIDEOS TABS (Isha Segmented Style)
                // -----------------------------------------
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.cardBorder(context)
                          .withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        context,
                        title: 'Audio',
                        tab: WisdomTab.audio,
                        icon: Icons.headphones_rounded,
                      ),
                      _buildTabButton(
                        context,
                        title: 'Videos',
                        tab: WisdomTab.videos,
                        icon: Icons.play_circle_fill_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                if (_selectedTab == WisdomTab.videos)
                  _buildVideosView(context)
                else
                  ref
                      .watch(bhajansGroupedProvider)
                      .when(
                        data: (groupedBhajans) {
                          if (groupedBhajans.isEmpty) {
                            return _buildEmptyState(context);
                          }

                          final allTracks = groupedBhajans.values
                              .expand((element) => element)
                              .toList();

                          const audioTags = ['All', 'Bhajans', 'Satsang'];

                          // Filter tracks based on selected category tag AND search query
                          List<AudioItem> displayedTracks = allTracks;

                          if (_selectedTag != null && _selectedTag != 'All') {
                            final tagQuery = _selectedTag!.toLowerCase();
                            displayedTracks = displayedTracks.where((track) {
                              return track.category.toLowerCase().contains(
                                    tagQuery,
                                  ) ||
                                  track.title.toLowerCase().contains(
                                    tagQuery,
                                  ) ||
                                  track.description.toLowerCase().contains(
                                    tagQuery,
                                  ) ||
                                  track.artist.toLowerCase().contains(tagQuery);
                            }).toList();
                          }

                          if (_searchQuery.trim().isNotEmpty) {
                            final query = _searchQuery.toLowerCase();
                            displayedTracks = displayedTracks.where((track) {
                              return track.title.toLowerCase().contains(
                                    query,
                                  ) ||
                                  track.artist.toLowerCase().contains(query) ||
                                  track.category.toLowerCase().contains(query);
                            }).toList();
                          }

                          displayedTracks.sort((a, b) {
                            final dateComp = b.createdAt.compareTo(a.createdAt);
                            if (dateComp != 0) return dateComp;
                            final bId = int.tryParse(b.id) ?? 0;
                            final aId = int.tryParse(a.id) ?? 0;
                            return bId.compareTo(aId);
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Filter Strip (With Filter Icon Chip)
                              SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      audioTags.length + 1, // +1 Filter Icon
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF260D12)
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.cardBorder(context),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          size: 18,
                                          color: AppTheme.primaryGold,
                                        ),
                                      );
                                    }

                                    final tagName = audioTags[index - 1];
                                    final isSelected =
                                        (_selectedTag == null &&
                                            tagName == 'All') ||
                                        _selectedTag == tagName;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTag = tagName == 'All'
                                              ? null
                                              : tagName;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 0,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryGold
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryGold
                                                : AppTheme.cardBorder(context),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryGold
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          tagName,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 13,
                                            color: isSelected
                                                ? AppTheme.darkBackground
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Audio Cards List (Sounds of Isha Style)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedTracks.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = displayedTracks[index];
                                  final isYouTube = item.audioUrl.contains(
                                    'youtu',
                                  );
                                  final isCurrentlyPlaying =
                                      !isYouTube &&
                                      ref
                                              .watch(audioProvider)
                                              .activeAudioSectionId ==
                                          'item_${item.id}';
                                  final isPlayingState =
                                      isCurrentlyPlaying &&
                                      ref.watch(audioProvider).isPlaying;
                                  final isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isCurrentlyPlaying
                                          ? (isDark
                                                ? AppTheme.primaryGold
                                                      .withValues(alpha: 0.10)
                                                : const Color(0xFFFFF8ED))
                                          : (isDark
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .surface
                                                : const Color(0xFFFAF7F2)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isCurrentlyPlaying
                                            ? AppTheme.primaryGold.withValues(
                                                alpha: 0.6,
                                              )
                                            : AppTheme.cardBorder(context),
                                        width: isCurrentlyPlaying ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () {
                                          if (isYouTube) {
                                            _openVideoPlayer(
                                              context,
                                              item,
                                              displayedTracks,
                                            );
                                          } else {
                                            if (!isCurrentlyPlaying) {
                                              final allDirectTracks =
                                                  (ref
                                                              .read(
                                                                allAudioTracksProvider,
                                                              )
                                                              .asData
                                                              ?.value ??
                                                          displayedTracks)
                                                      .where(
                                                        (t) =>
                                                            !t.audioUrl
                                                                .contains(
                                                                  'youtu',
                                                                ) &&
                                                            t
                                                                .audioUrl
                                                                .isNotEmpty,
                                                      )
                                                      .toList();
                                              ref
                                                  .read(audioProvider.notifier)
                                                  .playAudioItem(
                                                    item,
                                                    playlist: allDirectTracks,
                                                  );
                                            }
                                            _openPlayerSheet(context, ref);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14.0,
                                            vertical: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              // Square Album Thumbnail
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      item.coverImage.isNotEmpty
                                                          ? CachedNetworkImage(
                                                              imageUrl: item
                                                                  .coverImage,
                                                              fit: BoxFit.cover,
                                                              memCacheWidth:
                                                                  120,
                                                              memCacheHeight:
                                                                  120,
                                                              placeholder:
                                                                  (
                                                                    _,
                                                                    _,
                                                                  ) => Container(
                                                                    color:
                                                                        isDark
                                                                        ? Colors
                                                                              .grey[850]
                                                                        : Colors
                                                                              .grey[200],
                                                                  ),
                                                              errorWidget:
                                                                  (_, _, _) =>
                                                                      _defaultAudioThumb(
                                                                        isDark,
                                                                      ),
                                                            )
                                                          : _defaultAudioThumb(
                                                              isDark,
                                                            ),
                                                      if (isCurrentlyPlaying)
                                                        Container(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.55,
                                                              ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .graphic_eq_rounded,
                                                              color: AppTheme
                                                                  .primaryGold,
                                                              size: 22,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),

                                              // Title & Artist ONLY (No tags, no badges)
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                isCurrentlyPlaying
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .w600,
                                                            fontSize: 14.5,
                                                            color:
                                                                isCurrentlyPlaying
                                                                ? AppTheme
                                                                      .primaryGold
                                                                : Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onSurface,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                       item.artist,
                                                       maxLines: 1,
                                                       overflow:
                                                           TextOverflow.ellipsis,
                                                       style: TextStyle(
                                                         fontSize: 12,
                                                         color: Theme.of(
                                                           context,
                                                         ).colorScheme.onSurfaceVariant.withValues(
                                                           alpha: 0.7,
                                                         ),
                                                       ),
                                                     ),
                                                  ],
                                                ),
                                              ),

                                              // Trailing Actions (Download + Play Button)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (item.audioUrl.startsWith(
                                                        'http',
                                                      ) &&
                                                      !isYouTube)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 6.0,
                                                          ),
                                                      child: DownloadButton(
                                                        url: item.audioUrl,
                                                        iconColor:
                                                            isCurrentlyPlaying
                                                            ? AppTheme
                                                                  .primaryGold
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        hideIfDownloaded: false,
                                                        confirmBeforeDownload:
                                                            true,
                                                        showText: false,
                                                      ),
                                                    ),
                                                  GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTap: () {
                                                      if (isYouTube) {
                                                        _openVideoPlayer(
                                                          context,
                                                          item,
                                                          displayedTracks,
                                                        );
                                                      } else {
                                                        if (isCurrentlyPlaying) {
                                                          ref
                                                              .read(
                                                                audioProvider
                                                                    .notifier,
                                                              )
                                                              .togglePlayPause();
                                                        } else {
                                                          final allDirectTracks =
                                                              (ref
                                                                          .read(
                                                                            allAudioTracksProvider,
                                                                          )
                                                                          .asData
                                                                          ?.value ??
                                                                      displayedTracks)
                                                                  .where(
                                                                    (t) =>
                                                                        !t.audioUrl
                                                                            .contains(
                                                                              'youtu',
                                                                            ) &&
                                                                        t
                                                                            .audioUrl
                                                                            .isNotEmpty,
                                                                  )
                                                                  .toList();
                                                          ref
                                                              .read(
                                                                audioProvider
                                                                    .notifier,
                                                              )
                                                              .playAudioItem(
                                                                item,
                                                                playlist:
                                                                    allDirectTracks,
                                                              );
                                                        }
                                                        _openPlayerSheet(
                                                          context,
                                                          ref,
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isCurrentlyPlaying
                                                            ? AppTheme
                                                                  .primaryGold
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .surfaceContainerHighest
                                                                  .withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              isCurrentlyPlaying
                                                              ? AppTheme
                                                                    .primaryGold
                                                              : Theme.of(
                                                                      context,
                                                                    )
                                                                    .dividerColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.25,
                                                                    ),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child:
                                                            isCurrentlyPlaying &&
                                                                ref
                                                                    .watch(
                                                                      audioProvider,
                                                                    )
                                                                    .isLoading
                                                            ? const SizedBox(
                                                                width: 18,
                                                                height: 18,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: AppTheme
                                                                      .darkBackground,
                                                                ),
                                                              )
                                                            : Icon(
                                                                isPlayingState
                                                                    ? Icons
                                                                          .pause_rounded
                                                                    : Icons
                                                                          .play_arrow_rounded,
                                                                color:
                                                                    isCurrentlyPlaying
                                                                    ? AppTheme
                                                                          .darkBackground
                                                                    : AppTheme
                                                                          .primaryGold,
                                                                size: 20,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                        error: (err, stack) => _buildEmptyState(context),
                      ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAudioThumb(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C1E1E) : const Color(0xFFF3EAE0),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppTheme.primaryGold.withValues(alpha: 0.8),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String title,
    required WisdomTab tab,
    IconData? icon,
  }) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != tab) {
            setState(() {
              _selectedTab = tab;
              _selectedTag = null;
            });
          }
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? AppTheme.darkBackground
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    letterSpacing: 0.3,
                    color: isSelected
                        ? AppTheme.darkBackground
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosView(BuildContext context) {
    final videosAsync = ref.watch(videosProvider);

    return videosAsync.when(
      data: (videos) {
        List<AudioItem> displayedVideos = videos;
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          displayedVideos = videos.where((v) {
            return v.title.toLowerCase().contains(query) ||
                v.artist.toLowerCase().contains(query);
          }).toList();
        }

        if (displayedVideos.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedVideos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final item = displayedVideos[index];
                return _buildVideoCard(context, item, displayedVideos);
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              const Text('Could not load videos'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(videosProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideoPlayer(
    BuildContext context,
    AudioItem item,
    List<AudioItem> playlist,
  ) {
    if (ref.read(audioProvider).isPlaying) {
      ref.read(audioProvider.notifier).pause();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            YoutubeVideoScreen(item: item, playlist: playlist),
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    AudioItem item,
    List<AudioItem> allVideos,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('d MMM yyyy').format(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openVideoPlayer(context, item, allVideos),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Thumbnail with Isha-style Frosted Glass Play Button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: item.coverImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.coverImage,
                              fit: BoxFit.cover,
                              memCacheWidth: 600,
                              memCacheHeight: 338,
                              placeholder: (context, url) => Container(
                                color: isDark
                                    ? Colors.grey[850]
                                    : Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[200],
                                child: const Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 48,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          : Container(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[200],
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                size: 48,
                                color: Colors.red,
                              ),
                            ),
                    ),
                  ),
                  // Dark Vignette Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Center Frosted Play Button (Isha signature style)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  // Bottom-right YouTube Tag
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.red,
                            size: 11,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'YouTube',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Video Details below: Title & Date (No noisy badges!)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: AppTheme.serifFontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                        height: 1.28,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontFamily: AppTheme.currentFontFamily,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef AudioHubScreen = WisdomScreen;
typedef WisdomHubScreen = WisdomScreen;
