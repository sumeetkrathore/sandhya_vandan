import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'marquee_text.dart';


import '../providers/audio_provider.dart';
import '../models/audio_section.dart';

import '../screens/audio_player_screen.dart';
import '../theme/app_theme.dart';

class AudioMiniPlayer extends ConsumerWidget {
  final Widget? extraControls;
  final VoidCallback? onPlayPressed;
  final bool forceShow;

  const AudioMiniPlayer({
    super.key,
    this.extraControls,
    this.onPlayPressed,
    this.forceShow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? const Color(0xFF2D0D13)
        : const Color(0xFFFFFDF9);
    final borderColor = isDark
        ? AppTheme.primaryGold.withValues(alpha: 0.35)
        : AppTheme.cardBorderLight;
    final primaryTextColor = isDark
        ? AppTheme.primaryIvory
        : AppTheme.textPrimaryDark;

    final bool hasActiveAudio =
        audioState.isLoaded ||
        audioState.isLoading ||
        audioState.isPlaying ||
        audioState.currentAudioItem != null;

    if (!hasActiveAudio) {
      if (extraControls != null && !forceShow) {
        return Container(
          margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: extraControls!,
          ),
        );
      }

      if (!forceShow) {
        return const SizedBox.shrink();
      }
    }

    // Calculate progress (0.0 to 1.0)
    final double progress = audioState.duration.inMilliseconds > 0
        ? audioState.position.inMilliseconds /
              audioState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () {
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
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Bottom progress bar in radiant sacred gold gradient
              Positioned(
                left: 0,
                bottom: 0,
                right: 0,
                height: 3.5,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.linear,
                  tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return Container(
                      height: 3.5,
                      color: AppTheme.primaryGold.withValues(alpha: 0.12),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFC88A24),
                                AppTheme.primaryGold,
                                Color(0xFFF5D77F),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, -0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?extraControls,
                  if (extraControls != null)
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppTheme.cardBorderDark
                          : AppTheme.dividerLight,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        // Cover art thumbnail with rounded gold border
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryGold.withValues(
                                alpha: isDark ? 0.35 : 0.25,
                              ),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child:
                                  audioState
                                          .currentAudioItem
                                          ?.coverImage
                                          .isNotEmpty ==
                                      true
                                  ? CachedNetworkImage(
                                      imageUrl: audioState
                                          .currentAudioItem!
                                          .coverImage,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 96,
                                      memCacheHeight: 96,
                                      placeholder: (context, url) =>
                                          Image.asset(
                                            'assets/images/app_icon.png',
                                            fit: BoxFit.cover,
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Image.asset(
                                            'assets/images/app_icon.png',
                                            fit: BoxFit.cover,
                                          ),
                                    )
                                  : Image.asset(
                                      'assets/images/app_icon.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Track title (clean single-line with marquee)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Builder(
                              builder: (context) {
                                final String displayTitle;
                                if (audioState.currentAudioItem != null) {
                                  displayTitle =
                                      audioState.currentAudioItem!.title;
                                } else {
                                  AudioSection currentSection = audioSections
                                      .firstWhere(
                                        (s) =>
                                            s.id ==
                                            audioState.activeAudioSectionId,
                                        orElse: () => audioSections.first,
                                      );

                                  if (audioState.position.inSeconds > 0) {
                                    final matchingSections = audioSections
                                        .where(
                                          (s) =>
                                              s.id != 'full' &&
                                              s.startTimestamp != null &&
                                              audioState.position >=
                                                  s.startTimestamp!,
                                        )
                                        .toList();

                                    if (matchingSections.isNotEmpty) {
                                      currentSection = matchingSections.last;
                                    }
                                  }

                                  displayTitle = currentSection.id == 'full'
                                      ? 'Sandhya Vandan Nem'
                                      : currentSection.displayTitle;
                                }

                                return MarqueeText(
                                  text: displayTitle,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Play / Pause Circle with Golden Gradient
                        GestureDetector(
                          onTap: audioState.isLoading
                              ? null
                              : (onPlayPressed ??
                                    () => audioNotifier.togglePlayPause()),
                          child: Container(
                            width: 38,
                            height: 38,
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
                                  color: AppTheme.primaryGold.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: audioState.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.darkBackground,
                                      ),
                                    )
                                  : Icon(
                                      audioState.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppTheme.darkBackground,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Next Track Button
                        IconButton(
                          iconSize: 26,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          tooltip: 'Next Track',
                          icon: const Icon(Icons.skip_next_rounded),
                          color: isDark
                              ? AppTheme.warmText
                              : AppTheme.textPrimaryDark,
                          onPressed: () {
                            if (audioState.currentAudioItem != null &&
                                audioNotifier.hasNextTrack) {
                              audioNotifier.playNextTrack();
                            } else {
                              audioNotifier.skipForward();
                            }
                          },
                        ),
                        const SizedBox(width: 2),
                        // Close Dismiss Button
                        IconButton(
                          iconSize: 18,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(Icons.close_rounded),
                          color: isDark
                              ? AppTheme.warmText.withValues(alpha: 0.6)
                              : AppTheme.mutedText,
                          tooltip: 'Close Mini Player',
                          onPressed: () => audioNotifier.stop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
