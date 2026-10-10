import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';

import '../data/native_text_data.dart';
import '../models/native_text.dart';
import '../providers/settings_provider.dart';
import '../widgets/contents_drawer.dart';
import '../widgets/today_sandesh_card.dart';
import '../widgets/home_wisdom_section.dart';
import '../widgets/upcoming_events_carousel.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

bool _sessionHasShownLanguagePrompt = false;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _getSectionTitle(int index) {
    if (index >= 0 && index < nativeSections.length) {
      String title = nativeSections[index].headingRoman;
      if (title == 'Samadha Ashram Ji Ustati') {
        return 'Ustati';
      }
      if (title.startsWith('Aarti Sahib - ')) {
        return title.replaceFirst('Aarti Sahib - Satguru ', 'Aarti: ');
      }
      return title;
    }
    return "Sandhya Vandan";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (!settings.rememberLanguageChoice && !_sessionHasShownLanguagePrompt) {
        _sessionHasShownLanguagePrompt = true;
        _showLanguageSelector();
      }
      _checkForUpdates();
      ref.read(settingsProvider.notifier).incrementAppLaunchCount();
      _handleRatingPromptLogic(isClosing: false);
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Update ready to install.'),
              duration: const Duration(
                days: 365,
              ), // Keep it open until dismissed
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'RESTART',
                onPressed: () async {
                  await InAppUpdate.completeFlexibleUpdate();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // ignore errors if not from play store
    }
  }

  Future<void> _handleRatingPromptLogic({required bool isClosing}) async {
    final settings = ref.read(settingsProvider);
    if (settings.hasRatedApp) return;

    final int launchCount = settings.appLaunchCount;
    final int promptCount = settings.reviewPromptCount;
    final String lastDateStr = settings.lastReviewPromptDate;
    final DateTime? lastDate = lastDateStr.isNotEmpty
        ? DateTime.tryParse(lastDateStr)
        : null;

    bool shouldShow = false;

    if (promptCount == 0 && isClosing) {
      // First time users should popup when closing or backing the app
      shouldShow = true;
    } else if (promptCount == 1 && !isClosing && launchCount >= 5) {
      // If skipped first time, pop up after 5th or 6th time if opens
      shouldShow = true;
    } else if (promptCount >= 2 && !isClosing && lastDate != null) {
      // If still skips, then after a few days
      final daysSinceLast = DateTime.now().difference(lastDate).inDays;
      if (daysSinceLast >= 4) {
        // e.g. 4 days
        shouldShow = true;
      }
    }

    if (shouldShow) {
      try {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          ref.read(settingsProvider.notifier).logReviewPromptShown();
          await inAppReview.requestReview();
        }
      } catch (e) {
        // ignore errors
      }
    }
  }

  void _showLanguageSelector() {
    bool remember = ref.read(settingsProvider).rememberLanguageChoice;
    NativeLanguage selected = ref.read(settingsProvider).selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose reading language',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'سنڌي',
                        style: TextStyle(
                          fontFamily: AppTheme.sindhiRegularFont,
                          fontSize: 20,
                        ),
                      ),
                      trailing: selected == NativeLanguage.sindhi
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        setStateSheet(() {
                          selected = NativeLanguage.sindhi;
                        });
                        ref
                            .read(settingsProvider.notifier)
                            .setNativeLanguage(NativeLanguage.sindhi);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('हिन्दी'),
                      trailing: selected == NativeLanguage.hindi
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        setStateSheet(() {
                          selected = NativeLanguage.hindi;
                        });
                        ref
                            .read(settingsProvider.notifier)
                            .setNativeLanguage(NativeLanguage.hindi);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Roman'),
                      trailing: selected == NativeLanguage.roman
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        setStateSheet(() {
                          selected = NativeLanguage.roman;
                        });
                        ref
                            .read(settingsProvider.notifier)
                            .setNativeLanguage(NativeLanguage.roman);
                      },
                    ),
                    const Divider(height: 24),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remember my choice'),
                      value: remember,
                      onChanged: (val) {
                        setStateSheet(() {
                          remember = val ?? false;
                        });
                        ref
                            .read(settingsProvider.notifier)
                            .setRememberLanguageChoice(remember);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? lastReadSectionIndexNullable = ref.watch(
      lastReadAssetPageProvider,
    );
    final bool hasGenuineReadingProgress = ref.watch(
      genuineReadingProgressProvider,
    );
    final int lastReadSectionIndex = lastReadSectionIndexNullable ?? 0;
    final lastReadSection = _getSectionTitle(lastReadSectionIndex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final settings = ref.read(settingsProvider);
        if (!settings.hasRatedApp && settings.reviewPromptCount == 0) {
          await _handleRatingPromptLogic(isClosing: true);
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, size: 26),
                tooltip: 'Navigation Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          title: const Text('Sandhya Vandan'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: IconButton(
                icon: const Icon(Icons.settings_rounded, size: 24),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        drawer: const ContentsDrawer(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 36.0),
            children: [
              // Reading Block (Primary Action)
              ReadingProgressCard(
                lastReadSectionIndex: lastReadSectionIndex,
                hasGenuineReadingProgress: hasGenuineReadingProgress,
                lastReadSection: lastReadSection,
              ),
              const SizedBox(height: 24),

              // Today's Sandesh
              const TodaySandeshCard(),
              const SizedBox(height: 24),

              // Wisdom & Satsang (Newest Discourse Spotlight)
              const HomeWisdomSection(),
              const SizedBox(height: 24),

              // Upcoming Events
              const UpcomingEventsCarousel(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class ReadingProgressCard extends ConsumerWidget {
  final int lastReadSectionIndex;
  final bool hasGenuineReadingProgress;
  final String lastReadSection;

  const ReadingProgressCard({
    super.key,
    required this.lastReadSectionIndex,
    required this.hasGenuineReadingProgress,
    required this.lastReadSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = nativeSections.length;
    final currentPage = lastReadSectionIndex + 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkBrown = AppTheme.cardTextColor(context);
    final elevatedBtnText = isDark ? AppTheme.cardTextDarkBrown : Colors.white;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFFAF7F2);
    final borderColor = AppTheme.cardBorder(context);

    final bool isCompleted =
        hasGenuineReadingProgress && currentPage == totalPages;
    final bool isNotStarted = !hasGenuineReadingProgress;
    final bool showProgress = !isCompleted && !isNotStarted;

    Widget bookCover = Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderScreen(
                initialSectionIndex: showProgress ? lastReadSectionIndex : 0,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 165,
              child: Image.asset(
                'assets/images/page_01.jpeg',
                fit: BoxFit.contain,
                cacheHeight: 500,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Widget contentBlock = Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                showProgress
                    ? Icons.menu_book_rounded
                    : Icons.auto_stories_rounded,
                color: const Color.fromRGBO(221, 125, 59, 1),
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  showProgress ? 'CONTINUE READING' : 'START READING',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: darkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            showProgress ? lastReadSection : 'Sandhya Vandan',
            style: AppTheme.homeReadingCardTitle.copyWith(color: darkBrown),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (showProgress) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReaderScreen(
                            initialSectionIndex: lastReadSectionIndex,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBrown,
                      foregroundColor: elevatedBtnText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(genuineReadingProgressProvider.notifier).reset();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ReaderScreen(initialSectionIndex: 0),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkBrown,
                      side: BorderSide(color: darkBrown.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Start Over',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              "Mangla Charan, Satguru's Ustati, Arti Sahib, Prarthna and Dhyan",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(genuineReadingProgressProvider.notifier).reset();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ReaderScreen(initialSectionIndex: 0),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBrown,
                  foregroundColor: elevatedBtnText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Read Sandhya Vandan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [contentBlock, const SizedBox(width: 16), bookCover],
        ),
      ),
    );
  }
}

class AshramUpdatesCard extends StatelessWidget {
  const AshramUpdatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Placeholder for future navigation
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latest From Ashram',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Satguru's Yatra & Ashram Timings",
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
