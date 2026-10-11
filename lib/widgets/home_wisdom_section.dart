import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../repositories/audio_repository.dart';
import '../screens/wisdom_screen.dart';
import '../screens/youtube_video_screen.dart';
import '../theme/app_theme.dart';

class HomeWisdomSection extends ConsumerWidget {
  const HomeWisdomSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();

        final latestVideo = videos.first;
        final dateStr = DateFormat('d MMM yyyy').format(latestVideo.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header: Wisdom + See all
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Wisdom',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sectionTitleMain.copyWith(
                      color: isDark
                          ? AppTheme.primaryIvory
                          : AppTheme.deepBurgundy,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WisdomScreen()),
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
                          'See All',
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

            // Latest Video Spotlight Card
            Container(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YoutubeVideoScreen(
                          item: latestVideo,
                          playlist: videos,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 16:9 Thumbnail with Frosted Play Icon
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              latestVideo.coverImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: latestVideo.coverImage,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 600,
                                      memCacheHeight: 338,
                                    )
                                  : Container(color: Colors.grey[850]),
                              Center(
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.55,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Details
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestVideo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontFamily: AppTheme.serifFontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    height: 1.3,
                                    color: isDark
                                        ? AppTheme.primaryIvory
                                        : AppTheme.textPrimaryDark,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: AppTheme.currentFontFamily,
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.mutedText
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•  Pooj Samadha Ashram',
                                  style: TextStyle(
                                    fontFamily: AppTheme.currentFontFamily,
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.mutedText
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
