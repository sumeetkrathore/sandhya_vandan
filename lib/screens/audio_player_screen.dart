import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/audio_provider.dart';
import '../models/audio_section.dart';
import '../models/audio_item.dart';
import '../repositories/audio_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/download_button.dart';
import '../widgets/marquee_text.dart';

/// Isha-style animated delicate sound wave equalizer bars
class SoundWaveBars extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  final double size;

  const SoundWaveBars({
    super.key,
    required this.color,
    this.isPlaying = true,
    this.size = 16,
  });

  @override
  State<SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<SoundWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SoundWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final h1 = widget.isPlaying
              ? (0.35 + 0.65 * ((t + 0.0) % 1.0))
              : 0.45;
          final h2 = widget.isPlaying
              ? (0.20 + 0.80 * ((t + 0.5) % 1.0))
              : 0.85;
          final h3 = widget.isPlaying
              ? (0.45 + 0.55 * ((t + 0.25) % 1.0))
              : 0.60;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [_buildBar(h1), _buildBar(h2), _buildBar(h3)],
          );
        },
      ),
    );
  }

  Widget _buildBar(double heightFraction) {
    return Container(
      width: (widget.size / 4).clamp(2.0, 4.0),
      height: widget.size * heightFraction.clamp(0.25, 1.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Isha Foundation organic topographic dune / contour strata background painter
class IshaOrganicFluidAuraPainter extends CustomPainter {
  final double aura;
  final bool isDark;
  final Color primaryColor;

  IshaOrganicFluidAuraPainter({
    required this.aura,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final progress = aura * 2 * math.pi;

    // 1. Isha Earth Base Solid / Subtle Atmospheric Gradient
    // In dark mode: Rich warm deep mocha #433225 (matching exact Isha screenshot)
    // In light mode: Warm sandalwood cream #F3ECE2
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF48362A), // Top warm mocha
                Color(0xFF412F22), // Mid mocha
                Color(0xFF38271B), // Lower earth
              ]
            : const [
                Color(0xFFF7F0E7), // Top sandalwood ivory
                Color(0xFFEFE6D9), // Mid sandalwood
                Color(0xFFE5D9C8), // Earthy light
              ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Organic fluid movement: noticeable, graceful undulating motion
    final s1 = math.sin(progress) * 38.0;
    final c1 = math.cos(progress * 0.9) * 32.0;
    final s2 = math.sin(progress * 1.1 + 1.2) * 44.0;
    final c2 = math.cos(progress * 0.8 + 2.0) * 36.0;
    final s3 = math.sin(progress * 0.95 + 2.4) * 40.0;

    // Edge hairline contour paint with a delicate, soft blur
    final edgePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..color = (isDark ? Colors.white : Colors.black).withValues(
        alpha: isDark ? 0.09 : 0.07,
      );

    // -------------------------------------------------------------
    // Dune Layer 1: Top-Left Organic Strata
    // -------------------------------------------------------------
    final p1 = Path();
    p1.moveTo(-10, -10);
    p1.lineTo(w * 0.60 + c1, -10);
    p1.cubicTo(
      w * 0.45 + s1,
      h * 0.16 + c1,
      w * 0.18 + c2,
      h * 0.26 + s2,
      -10,
      h * 0.32 + s1,
    );
    p1.close();

    final fill1 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..color = (isDark ? Colors.white : Colors.black).withValues(
        alpha: isDark ? 0.05 : 0.04,
      );
    canvas.drawPath(p1, fill1);

    final edge1 = Path();
    edge1.moveTo(w * 0.60 + c1, 0);
    edge1.cubicTo(
      w * 0.45 + s1,
      h * 0.16 + c1,
      w * 0.18 + c2,
      h * 0.26 + s2,
      0,
      h * 0.32 + s1,
    );
    canvas.drawPath(edge1, edgePaint);

    // -------------------------------------------------------------
    // Dune Layer 2: Top-Right Lobe
    // -------------------------------------------------------------
    final p2 = Path();
    p2.moveTo(w + 10, -10);
    p2.lineTo(w * 0.62 + s2, -10);
    p2.cubicTo(
      w * 0.68 + c1,
      h * 0.18 + s1,
      w * 0.90 + s2,
      h * 0.34 + c2,
      w + 10,
      h * 0.40 + c1,
    );
    p2.close();

    final fill2 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..color = (isDark ? Colors.black : Colors.white).withValues(
        alpha: isDark ? 0.07 : 0.05,
      );
    canvas.drawPath(p2, fill2);

    final edge2 = Path();
    edge2.moveTo(w * 0.62 + s2, 0);
    edge2.cubicTo(
      w * 0.68 + c1,
      h * 0.18 + s1,
      w * 0.90 + s2,
      h * 0.34 + c2,
      w,
      h * 0.40 + c1,
    );
    canvas.drawPath(edge2, edgePaint);

    // -------------------------------------------------------------
    // Dune Layer 3: Main Sweeping Wave Behind Artwork & Track Info
    // -------------------------------------------------------------
    final p3 = Path();
    p3.moveTo(-10, h * 0.22 + c1);
    p3.cubicTo(
      w * 0.30 + s1,
      h * 0.36 + c2,
      w * 0.70 + c1,
      h * 0.20 + s2,
      w + 10,
      h * 0.34 + s3,
    );
    p3.lineTo(w + 10, h + 10);
    p3.lineTo(-10, h + 10);
    p3.close();

    final fill3 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..color = (isDark ? Colors.white : Colors.black).withValues(
        alpha: isDark ? 0.045 : 0.035,
      );
    canvas.drawPath(p3, fill3);

    final edge3 = Path();
    edge3.moveTo(0, h * 0.22 + c1);
    edge3.cubicTo(
      w * 0.30 + s1,
      h * 0.36 + c2,
      w * 0.70 + c1,
      h * 0.20 + s2,
      w,
      h * 0.34 + s3,
    );
    canvas.drawPath(edge3, edgePaint);

    // -------------------------------------------------------------
    // Dune Layer 4: Lower Wave Flowing Across Playback Controls
    // -------------------------------------------------------------
    final p4 = Path();
    p4.moveTo(-10, h * 0.58 + s2);
    p4.cubicTo(
      w * 0.35 + c1,
      h * 0.50 + s1,
      w * 0.72 + s3,
      h * 0.66 + c2,
      w + 10,
      h * 0.56 + s1,
    );
    p4.lineTo(w + 10, h + 10);
    p4.lineTo(-10, h + 10);
    p4.close();

    final fill4 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..color = (isDark ? Colors.black : Colors.white).withValues(
        alpha: isDark ? 0.08 : 0.06,
      );
    canvas.drawPath(p4, fill4);

    final edge4 = Path();
    edge4.moveTo(0, h * 0.58 + s2);
    edge4.cubicTo(
      w * 0.35 + c1,
      h * 0.50 + s1,
      w * 0.72 + s3,
      h * 0.66 + c2,
      w,
      h * 0.56 + s1,
    );
    canvas.drawPath(edge4, edgePaint);

    // -------------------------------------------------------------
    // Dune Layer 5: Deep Ground Wave Passing Under Up Next
    // -------------------------------------------------------------
    final p5 = Path();
    p5.moveTo(-10, h * 0.78 + c2);
    p5.cubicTo(
      w * 0.32 + s2,
      h * 0.84 + s1,
      w * 0.76 + c1,
      h * 0.74 + c2,
      w + 10,
      h * 0.80 + s3,
    );
    p5.lineTo(w + 10, h + 10);
    p5.lineTo(-10, h + 10);
    p5.close();

    final fill5 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..color = (isDark ? Colors.white : Colors.black).withValues(
        alpha: isDark ? 0.05 : 0.04,
      );
    canvas.drawPath(p5, fill5);

    final edge5 = Path();
    edge5.moveTo(0, h * 0.78 + c2);
    edge5.cubicTo(
      w * 0.32 + s2,
      h * 0.84 + s1,
      w * 0.76 + c1,
      h * 0.74 + c2,
      w,
      h * 0.80 + s3,
    );
    canvas.drawPath(edge5, edgePaint);
  }

  @override
  bool shouldRepaint(covariant IshaOrganicFluidAuraPainter oldDelegate) {
    return oldDelegate.aura != aura ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}

class AudioPlayerScreen extends ConsumerStatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _auraController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  void _shareCurrentTrack(AudioState audioState) {
    final item = audioState.currentAudioItem;
    final title = item?.title ?? 'Sandhya Vandan';
    final artist = (item?.artist.isNotEmpty == true)
        ? item!.artist
        : 'Sandhya Vandan';
    final audioUrl = item?.audioUrl ?? '';
    String shareContent =
        'Listen to "$title" by $artist on Sandhya Vandan App.';
    if (audioUrl.isNotEmpty && audioUrl.startsWith('http')) {
      shareContent += '\n\n$audioUrl';
    }
    SharePlus.instance.share(ShareParams(text: shareContent, subject: title));
  }

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _auraController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioState = ref.read(audioProvider);
      if (!audioState.isLoaded &&
          !audioState.isLoading &&
          audioState.currentAudioItem == null &&
          !audioState.isPlaying) {
        ref.read(audioProvider.notifier).prepareAudio();
      }
    });
  }

  @override
  void dispose() {
    _auraController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _updateAura(bool isPlaying) {
    if (!_auraController.isAnimating) {
      _auraController.repeat();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _defaultThumb(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF2C1E1E) : const Color(0xFFF3EAE0),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppTheme.primaryGold.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    final allAudiosAsync = ref.watch(allAudioTracksProvider);
    final playlist =
        (audioState.playlist.isNotEmpty
                ? audioState.playlist
                : (allAudiosAsync.asData?.value ?? []))
            .where(
              (item) =>
                  !item.audioUrl.contains('youtu') && item.audioUrl.isNotEmpty,
            )
            .toList();

    if (audioState.currentAudioItem != null &&
        audioState.playlist.isEmpty &&
        playlist.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(audioProvider).playlist.isEmpty &&
            playlist.isNotEmpty) {
          ref.read(audioProvider.notifier).setPlaylist(playlist);
        }
      });
    }

    ref.listen<AudioState>(audioProvider, (previous, next) {
      if (previous?.isPlaying != next.isPlaying) {
        _updateAura(next.isPlaying);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top > 0
        ? MediaQuery.of(context).viewPadding.top
        : (MediaQuery.of(context).padding.top > 0
              ? MediaQuery.of(context).padding.top
              : 36.0);

    return Material(
      color: isDark ? const Color(0xFF222325) : const Color(0xFFF4F0E8),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Isha Ambient Living Aura Background Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auraController,
              builder: (context, _) {
                if (!_auraController.isAnimating) {
                  _auraController.repeat();
                }
                final aura = _auraController.value;
                return CustomPaint(
                  painter: IshaOrganicFluidAuraPainter(
                    aura: aura,
                    isDark: isDark,
                    primaryColor: AppTheme.primaryGold,
                  ),
                );
              },
            ),
          ),
          // Foreground Audio Player UI with explicit Status Bar clearance
          Column(
            children: [
              SizedBox(height: statusBarHeight + 6),
              // Center drag pill with downward drag-to-dismiss gesture
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null &&
                      details.primaryDelta! > 7) {
                    Navigator.pop(context);
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 120) {
                    Navigator.pop(context);
                  }
                },
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.30,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // 1. Top Bar Header (Screenshot 3: Down arrow on left, Share on right)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Down Arrow to Minimize (matching Screenshot 3)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.25),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? Colors.white
                              : AppTheme.textPrimaryDark,
                          size: 28,
                        ),
                      ),
                    ),

                    // Center swipe-down drag area between Down Arrow and Share
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if (details.primaryDelta != null &&
                              details.primaryDelta! > 7) {
                            Navigator.pop(context);
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! > 120) {
                            Navigator.pop(context);
                          }
                        },
                        child: const SizedBox(height: 40),
                      ),
                    ),

                    // Right: Working Share Button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _shareCurrentTrack(audioState),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.25),
                        ),
                        child: Icon(
                          Icons.share_rounded,
                          color: isDark
                              ? Colors.white
                              : AppTheme.textPrimaryDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // 2. Devotional Artwork (Matching Isha Foundation rounded square)
                      Builder(
                        builder: (context) {
                          final screenW = MediaQuery.of(context).size.width;
                          final artSize = math.min(screenW * 0.78, 290.0);
                          return Container(
                            width: artSize,
                            height: artSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.45 : 0.20,
                                  ),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
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
                                      width: artSize,
                                      height: artSize,
                                      memCacheWidth: 600,
                                      memCacheHeight: 600,
                                      placeholder: (context, url) =>
                                          Image.asset(
                                            'assets/images/app_icon.png',
                                            fit: BoxFit.cover,
                                            width: artSize,
                                            height: artSize,
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Image.asset(
                                            'assets/images/app_icon.png',
                                            fit: BoxFit.cover,
                                            width: artSize,
                                            height: artSize,
                                          ),
                                    )
                                  : Image.asset(
                                      'assets/images/app_icon.png',
                                      fit: BoxFit.cover,
                                      width: artSize,
                                      height: artSize,
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // 3. Track Info Row (Left title & artist, Right circular (+))
                      Builder(
                        builder: (context) {
                          String displayTitle = 'Sandhya Vandan Nem';
                          String displaySubtitle = 'Sandhya Vandan';

                          if (audioState.currentAudioItem != null) {
                            displayTitle = audioState.currentAudioItem!.title;
                            if (audioState
                                .currentAudioItem!
                                .artist
                                .isNotEmpty) {
                              displaySubtitle =
                                  audioState.currentAudioItem!.artist;
                            }
                          } else {
                            AudioSection currentSection = audioSections
                                .firstWhere(
                                  (s) =>
                                      s.id == audioState.activeAudioSectionId,
                                  orElse: () => audioSections.first,
                                );
                            if (audioState.position.inSeconds > 0) {
                              final matches = audioSections
                                  .where(
                                    (s) =>
                                        s.id != 'full' &&
                                        s.startTimestamp != null &&
                                        audioState.position >=
                                            s.startTimestamp!,
                                  )
                                  .toList();
                              if (matches.isNotEmpty) {
                                currentSection = matches.last;
                              }
                            }
                            displayTitle = currentSection.id == 'full'
                                ? 'Sandhya Vandan Nem'
                                : currentSection.displayTitle;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26.0,
                            ),
                            child: Column(
                              children: [
                                MarqueeText(
                                  text: displayTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textPrimaryDark,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  displaySubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : AppTheme.textPrimaryDark)
                                            .withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 4. Scrubber (Sleek minimalist white slider matching Isha Foundation)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26.0),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.8,
                                activeTrackColor: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimaryDark,
                                inactiveTrackColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.22),
                                thumbColor: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimaryDark,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5.5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14.0,
                                ),
                                overlayColor:
                                    (isDark
                                            ? Colors.white
                                            : AppTheme.primaryGold)
                                        .withValues(alpha: 0.15),
                              ),
                              child: Slider(
                                min: 0.0,
                                max:
                                    audioState.duration.inMilliseconds
                                            .toDouble() >
                                        0
                                    ? audioState.duration.inMilliseconds
                                          .toDouble()
                                    : 1.0,
                                value: audioState.position.inMilliseconds
                                    .toDouble()
                                    .clamp(
                                      0.0,
                                      audioState.duration.inMilliseconds
                                                  .toDouble() >
                                              0
                                          ? audioState.duration.inMilliseconds
                                                .toDouble()
                                          : 1.0,
                                    ),
                                onChanged: (value) {
                                  audioNotifier.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(audioState.position),
                                    style: TextStyle(
                                      fontFamily: AppTheme.currentFontFamily,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (isDark
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryDark)
                                              .withValues(alpha: 0.65),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(audioState.duration),
                                    style: TextStyle(
                                      fontFamily: AppTheme.currentFontFamily,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (isDark
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryDark)
                                              .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. Hero Playback Controls (Translucent circular disc Play/Pause, matching Isha)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Repeat Mode
                            IconButton(
                              iconSize: 26,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: 'Repeat Mode',
                              icon: Icon(
                                audioState.repeatMode == AudioRepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                              ),
                              color:
                                  audioState.repeatMode != AudioRepeatMode.off
                                  ? (isDark
                                        ? Colors.white
                                        : AppTheme.primaryGold)
                                  : (isDark
                                            ? Colors.white
                                            : AppTheme.textPrimaryDark)
                                        .withValues(alpha: 0.5),
                              onPressed: () {
                                audioNotifier.toggleRepeatMode();
                              },
                            ),

                            // 2. Previous Track
                            IconButton(
                              iconSize: 38,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: 'Previous Track',
                              icon: const Icon(Icons.skip_previous_rounded),
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimaryDark,
                              onPressed: () {
                                if (audioState.currentAudioItem != null &&
                                    audioNotifier.hasPreviousTrack) {
                                  audioNotifier.playPreviousTrack();
                                } else {
                                  audioNotifier.skipBackward();
                                }
                              },
                            ),

                            // 3. Translucent Circular Disc Play/Pause Hero Button
                            GestureDetector(
                              onTap: audioState.isLoading
                                  ? null
                                  : () {
                                      if (!audioState.isLoaded &&
                                          audioState.currentAudioItem == null) {
                                        audioNotifier.play();
                                      } else {
                                        audioNotifier.togglePlayPause();
                                      }
                                    },
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.18),
                                ),
                                child: Center(
                                  child: audioState.isLoading
                                      ? SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.textPrimaryDark,
                                          ),
                                        )
                                      : Icon(
                                          audioState.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.textPrimaryDark,
                                          size: 38,
                                        ),
                                ),
                              ),
                            ),

                            // 4. Next Track
                            IconButton(
                              iconSize: 38,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: 'Next Track',
                              icon: const Icon(Icons.skip_next_rounded),
                              color: isDark
                                  ? Colors.white
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

                            // 5. Download Button for Offline Listening
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: DownloadButton(
                                  url:
                                      (audioState.activeAudioUrl?.isNotEmpty ==
                                          true)
                                      ? audioState.activeAudioUrl!
                                      : (audioState
                                                .currentAudioItem
                                                ?.audioUrl ??
                                            'https://audio.jaisamadha.com/sandya_vandan_master.m4a'),
                                  iconColor:
                                      (isDark
                                              ? Colors.white
                                              : AppTheme.textPrimaryDark)
                                          .withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 180),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. Snapping Frosted Draggable Sheet for Up Next Queue
          _buildUpNextDraggableSheet(
            context,
            audioState,
            audioNotifier,
            playlist,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildUpNextDraggableSheet(
    BuildContext context,
    AudioState audioState,
    AudioProviderNotifier audioNotifier,
    List<AudioItem> playlist,
    bool isDark,
  ) {
    final isSandhyaMode = audioState.currentAudioItem == null;
    final currentItem = audioState.currentAudioItem;
    final currentIdx = currentItem == null
        ? -1
        : playlist.indexWhere((it) => it.id == currentItem.id);
    final upNextList = (currentIdx != -1 && currentIdx < playlist.length - 1)
        ? playlist.sublist(currentIdx + 1)
        : (currentIdx == -1 ? playlist : <AudioItem>[]);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.18,
      minChildSize: 0.18,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.18, 0.88],
      snapAnimationDuration: const Duration(milliseconds: 200),
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: Container(
            decoration: BoxDecoration(
              color:
                  (isDark ? const Color(0xFF2C1E14) : const Color(0xFFF5EFE6))
                      .withValues(alpha: isDark ? 0.95 : 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Sticky / Persistent Drag Header
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        // Drag Handle Pill (pure drag target - zero tap interference)
                        Center(
                          child: Container(
                            width: 40,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Header: Isha-style Pill Button & Track Count Badge
                        Builder(
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (_sheetController.size < 0.35) {
                                        _sheetController.animateTo(
                                          0.88,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.fastOutSlowIn,
                                        );
                                      } else {
                                        _sheetController.animateTo(
                                          0.18,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.fastOutSlowIn,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                                .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSandhyaMode
                                                ? Icons
                                                      .format_list_bulleted_rounded
                                                : Icons.queue_music_rounded,
                                            size: 18,
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.textPrimaryDark,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            isSandhyaMode
                                                ? 'Sandhya Vandan Parts'
                                                : 'Up Next',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.2,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isSandhyaMode
                                          ? '${audioSections.length} Parts'
                                          : (upNextList.isNotEmpty
                                              ? '${upNextList.length} Up Next'
                                              : 'Last Track'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : AppTheme.textPrimaryDark
                                                  .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // 1. If playing Sandhya Vandan: Show all clickable Sandhya Vandan parts
                  if (audioState.currentAudioItem == null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index.isOdd) {
                            return const SizedBox(height: 8);
                          }
                          final secIndex = index ~/ 2;
                          final sec = audioSections[secIndex];

                          // Determine currently active section
                          AudioSection activeSec = audioSections.firstWhere(
                            (s) => s.id == audioState.activeAudioSectionId,
                            orElse: () => audioSections.first,
                          );
                          if (audioState.position.inSeconds > 0) {
                            final matches = audioSections
                                .where(
                                  (s) =>
                                      s.id != 'full' &&
                                      s.startTimestamp != null &&
                                      audioState.position >= s.startTimestamp!,
                                )
                                .toList();
                            if (matches.isNotEmpty) {
                              activeSec = matches.last;
                            }
                          }
                          final isPlayingSection = activeSec.id == sec.id;

                          return Material(
                            color: isPlayingSection
                                ? (isDark
                                      ? Colors.white.withValues(alpha: 0.14)
                                      : AppTheme.primaryGold.withValues(
                                          alpha: 0.15,
                                        ))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (isPlayingSection) {
                                  audioNotifier.togglePlayPause();
                                } else {
                                  audioNotifier.playSection(
                                    sec,
                                    autoPlay: true,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    // Leading number or soundwave indicator
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isPlayingSection
                                            ? (isDark
                                                  ? AppTheme.primaryGold
                                                        .withValues(alpha: 0.25)
                                                  : AppTheme.primaryGold
                                                        .withValues(
                                                          alpha: 0.20,
                                                        ))
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    )),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: isPlayingSection
                                            ? SoundWaveBars(
                                                color: AppTheme.primaryGold,
                                                isPlaying: audioState.isPlaying,
                                                size: 18,
                                              )
                                            : Text(
                                                '${secIndex + 1}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      (isDark
                                                              ? Colors.white
                                                              : AppTheme
                                                                    .textPrimaryDark)
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Section title & duration range
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MarqueeText(
                                            text: sec.displayTitle,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isPlayingSection
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isPlayingSection
                                                  ? (isDark
                                                        ? Colors.white
                                                        : AppTheme.primaryGold)
                                                  : (isDark
                                                        ? Colors.white
                                                        : AppTheme
                                                              .textPrimaryDark),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sec.startTimestamp != null &&
                                                    sec.endTimestamp != null
                                                ? '${_formatDuration(sec.startTimestamp!)} - ${_formatDuration(sec.endTimestamp!)}'
                                                : 'Complete Recitation • 46:34',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color:
                                                  (isDark
                                                          ? Colors.white
                                                          : AppTheme
                                                                .textPrimaryDark)
                                                      .withValues(alpha: 0.65),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isPlayingSection && audioState.isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: isPlayingSection
                                          ? (isDark
                                                ? Colors.white
                                                : AppTheme.primaryGold)
                                          : (isDark
                                                ? Colors.white38
                                                : AppTheme.textPrimaryDark
                                                      .withValues(alpha: 0.4)),
                                      size: 26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: audioSections.length * 2 - 1),
                      ),
                    )
                  // 2. If playing Bhajans: Pure "Up Next" list
                  else if (upNextList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.playlist_remove_rounded,
                                  size: 26,
                                  color: (isDark
                                          ? Colors.white
                                          : AppTheme.textPrimaryDark)
                                      .withValues(alpha: 0.40),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No upcoming tracks in queue',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: (isDark
                                          ? Colors.white
                                          : AppTheme.textPrimaryDark)
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You are listening to the last track of the playlist',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (isDark
                                          ? Colors.white
                                          : AppTheme.textPrimaryDark)
                                      .withValues(alpha: 0.40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index.isOdd) {
                              return const SizedBox(height: 8);
                            }
                            final itemIndex = index ~/ 2;
                            final item = upNextList[itemIndex];
                            return _buildTrackTile(
                              context: context,
                              item: item,
                              audioState: audioState,
                              audioNotifier: audioNotifier,
                              playlist: playlist,
                              isDark: isDark,
                            );
                          },
                          childCount: upNextList.length * 2 - 1,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackTile({
    required BuildContext context,
    required AudioItem item,
    required AudioState audioState,
    required AudioProviderNotifier audioNotifier,
    required List<AudioItem> playlist,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          audioNotifier.playAudioItem(
            item,
            playlist: playlist,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: item.coverImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.coverImage,
                          fit: BoxFit.cover,
                          memCacheWidth: 90,
                          memCacheHeight: 90,
                          placeholder: (c, u) => _defaultThumb(context),
                          errorWidget: (c, u, e) => _defaultThumb(context),
                        )
                      : _defaultThumb(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    Text(
                      item.artist.isNotEmpty
                          ? item.artist
                          : 'Pooj Samadha Ashram',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: (isDark
                            ? Colors.white54
                            : AppTheme.textPrimaryDark.withValues(
                                alpha: 0.55,
                              )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.audioUrl.startsWith('http'))
                DownloadButton(
                  url: item.audioUrl,
                  iconColor: isDark
                      ? Colors.white54
                      : AppTheme.textPrimaryDark.withValues(
                          alpha: 0.6,
                        )),
                  hideIfDownloaded: false,
                  confirmBeforeDownload: true,
                  showText: false,
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.play_circle_fill_rounded,
                color: isDark
                    ? Colors.white38
                    : AppTheme.textPrimaryDark.withValues(alpha: 0.4),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
