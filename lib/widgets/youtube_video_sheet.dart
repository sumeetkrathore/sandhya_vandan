import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/audio_item.dart';
import '../theme/app_theme.dart';

class YoutubeVideoSheet extends StatefulWidget {
  final AudioItem item;

  const YoutubeVideoSheet({super.key, required this.item});

  @override
  State<YoutubeVideoSheet> createState() => _YoutubeVideoSheetState();
}

class _YoutubeVideoSheetState extends State<YoutubeVideoSheet> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String videoId = widget.item.audioUrl;
    final match = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
    ).firstMatch(widget.item.audioUrl);
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
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92, // Full view (~92% of screen height)
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Header with [VIDEO] badge, title, and minimize button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'VIDEO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.title.isNotEmpty
                          ? widget.item.title
                          : 'Video Satsang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sheetTitle,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 30,
                    ),
                    tooltip: 'Minimize',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Embedded YouTube Video Player in full 16:9 width
            Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),

            // Scrollable details below video
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artist & Language Tags
                    Row(
                      children: [
                        if (widget.item.artist.isNotEmpty)
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
                            child: Text(
                              widget.item.artist,
                              style: const TextStyle(
                                color: AppTheme.primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (widget.item.language.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.item.language,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Full Title
                    Text(
                      widget.item.title,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold, height: 1.25),
                    ),
                    const SizedBox(height: 8),

                    // Description section (if present)
                    if (widget.item.description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Divider(
                        color: Theme.of(context).dividerColor
                            .withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'About this video',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.description,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
