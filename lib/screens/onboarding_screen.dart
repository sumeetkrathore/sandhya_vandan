import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/main_navigation.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Welcome to Sandhya Vandan",
      "text": "Carry your daily prayers and devotional texts anywhere you go. Read in English, Hindi, or native Sindhi script.",
      "icon": "book",
    },
    {
      "title": "Effortless Reading",
      "text": "Tap the left or right edges of the screen to quickly turn pages, or simply swipe across.",
      "icon": "swipe",
    },
    {
      "title": "Hands-Free Auto-Scroll",
      "text": "Tap the bottom edge of the reader to open the menu, where you can enable auto-scrolling and adjust its speed.",
      "icon": "scroll",
    },
    {
      "title": "Audio Hub & Downloads",
      "text": "Stream Sandhya Vandan and Bhajans directly, or tap the cloud icon to download them for offline listening anytime.",
      "icon": "audio",
    },
    {
      "title": "Make It Yours",
      "text": "Open Settings to adjust the font size, switch between Light and Dark themes, and choose your preferred language.",
      "icon": "settings",
    },
  ];

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case "book":
        return Icons.menu_book_rounded;
      case "swipe":
        return Icons.swipe_rounded;
      case "scroll":
        return Icons.swap_vert_circle_rounded;
      case "audio":
        return Icons.headphones_rounded;
      case "settings":
        return Icons.tune_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  void _completeOnboarding() {
    ref.read(settingsProvider.notifier).markOnboardingSeen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) {
                    setState(() {
                      _currentPage = value;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getIcon(_onboardingData[index]["icon"]!),
                                      size: 80,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                  Text(
                                    _onboardingData[index]["title"]!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _onboardingData[index]["text"]!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.5,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colorScheme.primary
                                : colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
