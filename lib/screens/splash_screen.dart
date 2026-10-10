import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_navigation.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _title1Fade;
  late Animation<double> _title2Fade;
  late Animation<double> _dividerFade;
  late Animation<double> _taglineFade;
  late Animation<double> _loadingFade;

  int _dotCount = 1;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );

    _title1Fade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeIn),
    );
    _title2Fade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
    );
    _dividerFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
    );
    _taglineFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
    );
    _loadingFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    // Dynamic Loading Dots Timer (updates dotCount every 400ms)
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount % 3) + 1;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final disableAnimations = MediaQuery.of(context).disableAnimations;

      Future.wait([_runAnimation(disableAnimations), appInitialization])
          .then((_) {
            if (mounted) _navigateToNext();
          })
          .catchError((e) {
            if (mounted) _navigateToNext();
          });
    });
  }

  Future<void> _runAnimation(bool disableAnimations) async {
    if (disableAnimations) {
      _mainController.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 400));
    } else {
      await _mainController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _navigateToNext() {
    final hasSeenOnboarding = ref.read(settingsProvider).hasSeenOnboarding;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSeenOnboarding
            ? const MainNavigation()
            : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme System Overlay
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    // Theme Tokens
    final logoAsset = isDark
        ? 'assets/images/Logo.White.webp'
        : 'assets/images/Logo.Black.webp';
    final accentGold = isDark
        ? const Color(0xFFD2A64A)
        : const Color(0xFFB88A3B);
    final primaryText = isDark
        ? const Color(0xFFFAF7F2)
        : const Color(0xFF4A121C);
    final secondaryText = isDark
        ? const Color(0xFFE0BB68)
        : const Color(0xFF76534A);
    final taglineText = isDark
        ? const Color(0xFFE5D5C5)
        : const Color(0xFF5C3D35);
    final scaffoldBg = isDark
        ? const Color(0xFF24070D)
        : const Color(0xFFFAF7F2);

    final overlayColors = isDark
        ? [
            const Color(0xFF24070D).withValues(alpha: 0.86),
            const Color(0xFF3A0D16).withValues(alpha: 0.80),
            const Color(0xFF4A121C).withValues(alpha: 0.88),
            const Color(0xFF1F050A).withValues(alpha: 0.94),
          ]
        : [
            const Color(0xFFFAF7F2).withValues(alpha: 0.94),
            const Color(0xFFF7EBDD).withValues(alpha: 0.90),
            const Color(0xFFEEDCCB).withValues(alpha: 0.92),
            const Color(0xFFE5CCB5).withValues(alpha: 0.97),
          ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // 1. BACKGROUND ASHRAM PHOTOGRAPH
          Positioned.fill(
            child: Image.asset(
              'assets/images/ashram_splash.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              color: isDark
                  ? null
                  : const Color(0xFF76534A).withValues(alpha: 0.12),
              colorBlendMode: isDark ? null : BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: scaffoldBg);
              },
            ),
          ),

          // 2. SOFT SACRED BLEND OVERLAY (Theme Adaptive Gradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: overlayColors,
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // 3. RESPONSIVE SPLASH CONTENT
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 3),

                            // 1. LOGO: SA SHIKARPUR (Theme Adaptive with Ambient Radial Glow)
                            AnimatedBuilder(
                              animation: _mainController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _logoFade.value,
                                  child: Transform.scale(
                                    scale: 0.9 + (_logoScale.value * 0.1),
                                    child: child,
                                  ),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle Sacred Ambient Radial Glow
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          accentGold.withValues(
                                            alpha: isDark ? 0.28 : 0.18,
                                          ),
                                          accentGold.withValues(
                                            alpha: isDark ? 0.08 : 0.04,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.55, 1.0],
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    logoAsset,
                                    height: 76,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox(height: 76);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 2. MAIN TITLE: SANDHYA VANDAN
                            AnimatedBuilder(
                              animation: _title1Fade,
                              builder: (context, child) => Opacity(
                                opacity: _title1Fade.value,
                                child: child!,
                              ),
                              child: Text(
                                'SANDHYA VANDAN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4.0,
                                  height: 1.2,
                                  color: primaryText,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 3. SUB TEXT: JAI SAMADHA
                            AnimatedBuilder(
                              animation: _title2Fade,
                              builder: (context, child) => Opacity(
                                opacity: _title2Fade.value,
                                child: child!,
                              ),
                              child: Text(
                                'Jai Samadha',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.currentFontFamily,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.0,
                                  color: secondaryText,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // DECORATIVE DIVIDER
                            AnimatedBuilder(
                              animation: _dividerFade,
                              builder: (context, child) => Opacity(
                                opacity: _dividerFade.value,
                                child: child!,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 1,
                                    width: 40,
                                    color: accentGold.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Transform.rotate(
                                    angle: math.pi / 4,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      color: accentGold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 1,
                                    width: 40,
                                    color: accentGold.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // TAGLINE SUB TEXT
                            AnimatedBuilder(
                              animation: _taglineFade,
                              builder: (context, child) => Opacity(
                                opacity: _taglineFade.value,
                                child: child!,
                              ),
                              child: Text(
                                "Immerse Yourself in Nem, Satguru's Dhyan & Ustati",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.currentFontFamily,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.4,
                                  height: 1.5,
                                  color: taglineText,
                                ),
                              ),
                            ),

                            const Spacer(flex: 4),

                            // DYNAMIC DOTS INDICATOR (• / •• / •••)
                            AnimatedBuilder(
                              animation: _loadingFade,
                              builder: (context, child) {
                                final dotsString = List.generate(
                                  _dotCount,
                                  (_) => '•',
                                ).join(' ');
                                return Opacity(
                                  opacity: _loadingFade.value,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        dotsString,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4.0,
                                          color: accentGold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
