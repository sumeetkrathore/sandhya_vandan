import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ashrams_screen.dart';
import 'programs_screen.dart';
import 'notifications_screen.dart';
import 'tipno_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/frosted_app_bar.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FrostedAppBar(title: 'Explore'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // ---------------------------------------------------------
          // EXPLORE LIST CARDS
          // ---------------------------------------------------------
          _buildListCard(
            context,
            title: 'Tipno',
            subtitle: 'Monthly Dharmic Events',
            icon: Icons.calendar_month_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TipnoScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _buildListCard(
            context,
            title: 'Programs',
            subtitle: 'Latest Ashram Events, Annual Varsi Utsavs and more',
            icon: Icons.event_available_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProgramsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _buildListCard(
            context,
            title: 'Ashrams',
            subtitle: 'Ashrams in Pakistan and India',
            icon: Icons.location_city_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AshramsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _buildListCard(
            context,
            title: 'Updates',
            subtitle: 'Ashram Sandesh, divine notices & utsav announcements',
            icon: Icons.notifications_active_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? AppTheme.elevatedBurgundy.withValues(alpha: 0.7)
        : Colors.white;

    final borderColor = isDark
        ? AppTheme.cardBorderDark
        : AppTheme.cardBorderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.primaryGold.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 24, color: AppTheme.primaryGold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.primaryGold.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
