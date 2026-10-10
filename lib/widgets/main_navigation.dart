import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home_screen.dart';
import '../screens/wisdom_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/satgurus_screen.dart';
import '../widgets/audio_mini_player.dart';
import '../providers/audio_provider.dart';

import '../data/native_text_data.dart';
import '../theme/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_router.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationRouter().onAppReady();
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // READ ACTION
      _handleReadAction();
    } else {
      // HOME (0), SATGURUS (1), AUDIO (3), MORE (4)
      setState(() {
        if (index < 2) {
          _currentIndex = index;
        } else if (index > 2) {
          _currentIndex = index - 1;
        }
      });
    }
  }

  void _handleReadAction() async {
    final prefs = await SharedPreferences.getInstance();
    final int lastReadSectionIndex =
        prefs.getInt('last_read_asset_page_v3') ?? 0;
    final bool hasGenuineReadingProgress = lastReadSectionIndex > 0;

    if (!mounted) return;

    if (!hasGenuineReadingProgress) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReaderScreen(initialSectionIndex: 0),
        ),
      );
    } else {
      _showContinueReadingSheet(lastReadSectionIndex);
    }
  }

  void _showContinueReadingSheet(int lastReadSectionIndex) {
    String sectionTitle = "Sandhya Vandan";
    if (lastReadSectionIndex >= 0 &&
        lastReadSectionIndex < nativeSections.length) {
      sectionTitle = nativeSections[lastReadSectionIndex].headingRoman;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Material(
          color: AppTheme.darkBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue Reading',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryIvory,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sectionTitle,
                    style: TextStyle(color: AppTheme.primaryGold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
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
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: AppTheme.darkBackground,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue Reading',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ReaderScreen(initialSectionIndex: 0),
                        ),
                      );
                    },
                    child: const Text(
                      'Start from Beginning',
                      style: TextStyle(color: AppTheme.warmText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // To map the BottomNavigationBar index (0..4) back to what is shown active
  int _getEffectiveBottomNavIndex() {
    if (_currentIndex == 0) return 0; // Home
    if (_currentIndex == 1) return 1; // Satgurus
    if (_currentIndex == 2) return 3; // Audio
    if (_currentIndex == 3) return 4; // More
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          SatgurusScreen(),
          WisdomScreen(),
          ExploreScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Global Mini Player sitting firmly above the navigation bar
          Consumer(
            builder: (context, ref, child) {
              final audioState = ref.watch(audioProvider);
              final isAudioActive =
                  audioState.isPlaying ||
                  audioState.isLoaded ||
                  audioState.isLoading ||
                  audioState.currentAudioItem != null;
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isAudioActive
                    ? const AudioMiniPlayer()
                    : const SizedBox.shrink(),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.elevatedBurgundy,
              border: Border(
                top: BorderSide(color: AppTheme.cardBorder(context), width: 1),
              ),
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _getEffectiveBottomNavIndex(),
                onTap: _onItemTapped,
                backgroundColor: AppTheme.elevatedBurgundy,
                selectedItemColor: AppTheme.primaryGold,
                unselectedItemColor: AppTheme.mutedText,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.spa),
                    label: 'Satgurus',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.darkBackground,
                        size: 24,
                      ),
                    ),
                    label: 'READ',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.play_circle_outline_rounded),
                    activeIcon: Icon(Icons.play_circle_rounded),
                    label: 'Wisdom',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_rounded),
                    label: 'Explore',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
