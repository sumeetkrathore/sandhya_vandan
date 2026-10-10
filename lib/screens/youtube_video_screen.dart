import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/audio_item.dart';
import '../theme/app_theme.dart';

class YoutubeVideoScreen extends StatefulWidget {
  final AudioItem item;
  final List<AudioItem>? playlist;

  const YoutubeVideoScreen({super.key, required this.item, this.playlist});

  @override
  State<YoutubeVideoScreen> createState() => _YoutubeVideoScreenState();
}

class _YoutubeVideoScreenState extends State<YoutubeVideoScreen> {
  late YoutubePlayerController _controller;
  late AudioItem _currentItem;
  bool _isLandscape = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;

    _initController(_currentItem.audioUrl);
  }

  void _initController(String url) {
    String videoId = url;
    final match = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
    ).firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      videoId = match.group(1)!;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: true,
        showVideoAnnotations: true,
      ),
    );

    // Listen to full screen button clicks from the YouTube player controls
    _controller.setFullScreenListener((isFullScreen) {
      _setOrientation(isFullScreen);
    });
  }

  void _setOrientation(bool isFullScreen) {
    if (_isLandscape == isFullScreen) return;

    setState(() {
      _isLandscape = isFullScreen;
    });

    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _playNextVideo(AudioItem nextItem) {
    String videoId = nextItem.audioUrl;
    final match = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
    ).firstMatch(nextItem.audioUrl);
    if (match != null && match.groupCount >= 1) {
      videoId = match.group(1)!;
    }

    setState(() {
      _currentItem = nextItem;
      _isDescriptionExpanded = false;
    });
    _controller.loadVideoById(videoId: videoId);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape || _isLandscape;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('d MMM yyyy').format(_currentItem.createdAt);
    final upNextList =
        (widget.playlist?.where((v) => v.id != _currentItem.id).toList() ?? [])
          ..sort((a, b) {
            final dateComp = b.createdAt.compareTo(a.createdAt);
            if (dateComp != 0) return dateComp;
            final bId = int.tryParse(b.id) ?? 0;
            final aId = int.tryParse(a.id) ?? 0;
            return bId.compareTo(aId);
          });

    final playerWidth = size.width;
    final playerHeight = isLandscape ? size.height : size.width * (9 / 16);

    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: PopScope(
        canPop: !isLandscape,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && isLandscape) {
            _setOrientation(false);
          }
        },
        child: Scaffold(
          backgroundColor: isLandscape
              ? Colors.black
              : Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            top: !isLandscape,
            bottom: false,
            left: false,
            right: false,
            child: Column(
              children: [
                // 1. YouTube Player Docked at Top (Never destroyed on rotate so playback continues seamlessly)
                SizedBox(
                  width: playerWidth,
                  height: playerHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: YoutubePlayer(
                          key: const ValueKey('youtube_active_player'),
                          controller: _controller,
                          aspectRatio: isLandscape
                              ? (playerWidth / playerHeight)
                              : 16 / 9,
                        ),
                      ),

                      // Floating Back Chevron (Top-Right so top-left YouTube title/channel controls stay unblocked)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          radius: 18,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            tooltip: 'Close',
                            onPressed: () {
                              if (isLandscape) {
                                _setOrientation(false);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Details & Related Content (Portrait only)
                if (!isLandscape)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prominent Video Title (FedraSerifA Bold - Generous & Clear)
                          Text(
                            _currentItem.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 21,
                                  height: 1.32,
                                  color: isDark
                                      ? AppTheme.primaryIvory
                                      : AppTheme.textPrimaryDark,
                                ),
                          ),
                          const SizedBox(height: 8),

                          // Metadata: Date on Left, Share Button on Right (Matching Feed Cards)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontFamily: AppTheme.currentFontFamily,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.mutedText
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.75),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (_currentItem.audioUrl.isNotEmpty) {
                                    SharePlus.instance.share(
                                      ShareParams(
                                        text:
                                            '${_currentItem.title}\n${_currentItem.audioUrl}',
                                        subject: _currentItem.title,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.share_outlined,
                                        size: 16,
                                        color: isDark
                                            ? AppTheme.primaryGold
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          fontFamily:
                                              AppTheme.currentFontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppTheme.primaryGold
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Expandable Description Box (YouTube Mobile Spec Spacing)
                          if (_currentItem.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isDescriptionExpanded =
                                      !_isDescriptionExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.elevatedBurgundy
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.cardBorder(context),
                                    width: 1,
                                  ),
                                ),
                                child: _isDescriptionExpanded
                                    ? Text(
                                        _currentItem.description.trim(),
                                        style: TextStyle(
                                          fontFamily:
                                              AppTheme.currentFontFamily,
                                          fontSize: 13.5,
                                          height: 1.45,
                                          color: isDark
                                              ? AppTheme.warmText
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                        ),
                                      )
                                    : ShaderMask(
                                        shaderCallback: (bounds) {
                                          return const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            stops: [0.0, 0.6, 1.0],
                                            colors: [
                                              Colors.black,
                                              Colors.black,
                                              Colors.transparent,
                                            ],
                                          ).createShader(bounds);
                                        },
                                        blendMode: BlendMode.dstIn,
                                        child: Text(
                                          _currentItem.description.trim(),
                                          maxLines: 3,
                                          overflow: TextOverflow.clip,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTheme.currentFontFamily,
                                            fontSize: 13.5,
                                            height: 1.45,
                                            color: isDark
                                                ? AppTheme.warmText
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],

                          // Related Content Tiles List
                          if (upNextList.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Divider(
                              color: AppTheme.cardBorder(context),
                              height: 1,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Related Content',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontFamily: AppTheme.serifFontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark
                                        ? AppTheme.primaryIvory
                                        : AppTheme.textPrimaryDark,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: upNextList.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final item = upNextList[index];
                                final date = DateFormat('d MMM yyyy')
                                    .format(item.createdAt);

                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _playNextVideo(item),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 125,
                                          height: 72,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              item.coverImage.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: item.coverImage,
                                                      fit: BoxFit.cover,
                                                      memCacheWidth: 250,
                                                      memCacheHeight: 144,
                                                    )
                                                  : Container(
                                                      color: Colors.grey[850],
                                                    ),
                                              Center(
                                                child: CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  child: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTheme.serifFontFamily,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                height: 1.25,
                                                color: isDark
                                                    ? AppTheme.primaryIvory
                                                    : AppTheme.textPrimaryDark,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              date,
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTheme.currentFontFamily,
                                                fontSize: 11.5,
                                                color: isDark
                                                    ? AppTheme.mutedText
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
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
  }
}
