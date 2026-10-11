import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/notifications_provider.dart';
import '../models/notification_update.dart';
import '../theme/app_theme.dart';
import '../widgets/frosted_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFF9F7F4); // Very light warm gray/off-white

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const FrostedAppBar(title: 'Updates'),
      body: notificationsState.when(
        data: (updates) {
          if (updates.isEmpty) {
            return _buildEmptyState(context, isDark);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: updates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return NotificationCard(update: updates[index], isDark: isDark);
              },
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load updates'),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF8C7A6B);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent updates',
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationUpdate update;
  final bool isDark;

  const NotificationCard({
    super.key,
    required this.update,
    required this.isDark,
  });

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF2C1E16);
    final excerptColor = isDark ? Colors.white70 : const Color(0xFF6B5D54);
    final timeColor = isDark ? Colors.white38 : const Color(0xFF9E8F82);

    final bool hasImage =
        update.imageUrl != null && update.imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF4A2B2B).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Future navigation if needed
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: update.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  memCacheHeight: 280,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: Colors.grey.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 140,
                    color: Colors.grey.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (update.isSandesh) ...[
                          Icon(
                            Icons.format_quote_rounded,
                            size: 20,
                            color: AppTheme.secondarySaffron,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            update.title,
                            style: TextStyle(
                              fontFamily: AppTheme.serifFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (update.excerpt.isNotEmpty) ...[
                      Text(
                        update.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.currentFontFamily,
                          fontSize: 14,
                          color: excerptColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: timeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(update.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: timeColor,
                          ),
                        ),
                        if (update.type != 'post') ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondarySaffron.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              update.type.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondarySaffron,
                              ),
                            ),
                          ),
                        ],
                      ],
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
