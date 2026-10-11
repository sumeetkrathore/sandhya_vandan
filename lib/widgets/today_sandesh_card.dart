import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/sandesh.dart';
import '../providers/sandesh_provider.dart';
import '../screens/sandesh_detail_screen.dart';
import '../theme/app_theme.dart';
import 'sandesh_share_dialog.dart';

class TodaySandeshCard extends ConsumerWidget {
  const TodaySandeshCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildCard(context, ref);
  }

  Widget _buildCard(BuildContext context, WidgetRef ref) {
    final sandeshState = ref.watch(sandeshProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkBrown = AppTheme.cardTextColor(context);
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFFAF7F2);
    final borderColor = AppTheme.cardBorder(context);

    final currentSandesh = sandeshState.value;
    final hasImage =
        currentSandesh?.imageUrl != null &&
        currentSandesh!.imageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outer Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            "Today's Sandesh",
            style: AppTheme.sectionTitleMain.copyWith(
              color: isDark ? AppTheme.primaryIvory : AppTheme.deepBurgundy,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: currentSandesh != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SandeshDetailScreen(sandesh: currentSandesh),
                        ),
                      );
                    }
                  : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: currentSandesh.imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      memCacheHeight: 338,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: isDark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        highlightColor: isDark
                            ? Colors.grey[700]!
                            : Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: hasImage ? 22 : 26,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sandeshState.isLoading && sandeshState.value == null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      sandeshState.when(
                        data: (sandesh) {
                          if (sandesh == null) {
                            return Text(
                              "No Sandesh available.",
                              style: TextStyle(color: darkBrown),
                            );
                          }
                          return _buildSandeshContent(
                            context,
                            sandesh,
                            darkBrown,
                            hasImage: hasImage,
                          );
                        },
                        loading: () => sandeshState.value != null
                            ? _buildSandeshContent(
                                context,
                                sandeshState.value!,
                                darkBrown,
                                hasImage: hasImage,
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  "Loading Sandesh...",
                                  style: TextStyle(color: darkBrown),
                                ),
                              ),
                        error: (error, stack) => sandeshState.value != null
                            ? _buildSandeshContent(
                                context,
                                sandeshState.value!,
                                darkBrown,
                                hasImage: hasImage,
                              )
                            : Text(
                                "Today's Sandesh is temporarily unavailable.",
                                style: TextStyle(color: darkBrown),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);
  }

  Widget _buildSandeshContent(
    BuildContext context,
    Sandesh sandesh,
    Color darkBrown, {
    bool hasImage = false,
  }) {
    final String dateString =
        "${_getAbbrMonth(sandesh.date.month)}, ${sandesh.date.day.toString().padLeft(2, '0')} ${sandesh.date.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasImage) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '“',
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondarySaffron,
                height: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
            LayoutBuilder(
              builder: (context, constraints) {
                final style = TextStyle(
                  fontFamily: AppTheme.serifFontFamily,
                  fontSize: 17.0,
                  height: 1.55,
                  color: darkBrown,
                );

                final span = TextSpan(text: sandesh.content, style: style);
                final tp = TextPainter(
                  text: span,
                  maxLines: 7,
                  textDirection: TextDirection.ltr,
                );
                tp.layout(maxWidth: constraints.maxWidth);
                final isLong = tp.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sandesh.content,
                      textAlign: TextAlign.left,
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dynamic Date below Sandesh text
                        Text(
                          dateString,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: darkBrown.withValues(alpha: 0.7),
                          ),
                        ),
                        // Actions below Sandesh text: Share & Read Full
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                SandeshShareDialog.show(context, sandesh);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.share_rounded,
                                      size: 15,
                                      color: AppTheme.secondarySaffron,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        fontFamily: AppTheme.currentFontFamily,
                                        color: AppTheme.secondarySaffron,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isLong) ...[
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Read Full',
                                    style: TextStyle(
                                      fontFamily: AppTheme.currentFontFamily,
                                      color: AppTheme.secondarySaffron,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: AppTheme.secondarySaffron,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        );
  }

  String _getAbbrMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
