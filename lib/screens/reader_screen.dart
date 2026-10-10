import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/reading_sequence.dart';
import '../models/native_text.dart';

import '../widgets/native_section_widget.dart';
import '../providers/settings_provider.dart';
import '../widgets/audio_mini_player.dart';
import '../models/audio_section.dart';
import '../providers/audio_provider.dart';
import '../widgets/contents_drawer.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

bool _showSwipeHints = true;

class ReaderScreen extends ConsumerStatefulWidget {
  final int initialSectionIndex;

  const ReaderScreen({super.key, this.initialSectionIndex = 0});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late ScrollController _scrollController;

  late final ValueNotifier<int> _currentSequenceIndexNotifier;
  final ValueNotifier<bool> _controlsVisibleNotifier = ValueNotifier<bool>(
    true,
  );
  late ReadingSequence _sequence;
  final Map<int, GlobalKey> _itemKeys = {};

  double _accumulatedDownScroll = 0.0;
  Timer? _hideTimer;
  int? _bookmarkedAssetPage;
  Timer? _scrollDebounce;
  bool _needsScrollJump = false;
  ReadingMode? _lastReadingMode;

  @override
  void initState() {
    super.initState();
    _sequence = ReadingSequence.build();
    final initialIdx = widget.initialSectionIndex.clamp(
      0,
      _sequence.items.length - 1,
    );
    _currentSequenceIndexNotifier = ValueNotifier<int>(initialIdx);
    _needsScrollJump = true;

    _scrollController = ScrollController();
    _pageController = PageController(initialPage: initialIdx);
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(settingsProvider).keepScreenAwake) {
      WakelockPlus.enable();
    }
    _hideSwipeHints();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveLastPosition(initialIdx);
      _autoStartAudioIfNeeded(initialIdx);
    });

    _controlsVisibleNotifier.addListener(_onControlsVisibilityChanged);
  }

  void _autoStartAudioIfNeeded(int index) {
    final autoPlaySetting = ref.read(settingsProvider).autoPlayAudio;
    if (!autoPlaySetting) return;

    final audioState = ref.read(audioProvider);
    final nativeSection = _sequence.items[index];
    final audioSection = _mapNativeToAudioSection(nativeSection.id);

    final mainUrl = ref.read(audioProvider.notifier).mainSandhyaVandanUrl;
    if (!audioState.isPlaying || audioState.activeAudioUrl != mainUrl) {
      ref
          .read(audioProvider.notifier)
          .playSandhyaVandan(
            sectionId: audioSection?.id ?? 'full',
            autoPlay: true,
          );
    }
  }

  void _onControlsVisibilityChanged() {
    if (_controlsVisibleNotifier.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    _controlsVisibleNotifier.removeListener(_onControlsVisibilityChanged);
    _controlsVisibleNotifier.dispose();
    _currentSequenceIndexNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final keepAwake = ref.read(settingsProvider).keepScreenAwake;
    if (state == AppLifecycleState.resumed && keepAwake) {
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      WakelockPlus.disable();
    }
  }

  void _hideSwipeHints() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSwipeHints = false;
        });
      }
    });
  }

  String _getAppBarTitle(NativeLanguage language, int index) {
    if (index < 0 || index >= _sequence.items.length) {
      return '';
    }
    final section = _sequence.items[index];
    if (language == NativeLanguage.sindhi) {
      return section.headingSindhi;
    } else if (language == NativeLanguage.hindi &&
        section.headingHindi != null) {
      return TextUtils.toDevanagariDigits(section.headingHindi!);
    } else {
      return section.headingRoman;
    }
  }

  Future<void> _saveLastPosition(int logicalIndex) async {
    ref.read(lastReadAssetPageProvider.notifier).updatePage(logicalIndex);
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_controlsVisibleNotifier.value) {
      _hideTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) {
          _controlsVisibleNotifier.value = false;
        }
      });
    }
  }

  void _toggleControls() {
    _controlsVisibleNotifier.value = !_controlsVisibleNotifier.value;
    if (_controlsVisibleNotifier.value) {
      _accumulatedDownScroll = 0.0;
      _resetHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  AudioSection? _mapNativeToAudioSection(String nativeId) {
    switch (nativeId) {
      case 'MANGALA_CHARAN':
        return audioSections.firstWhere(
          (s) => s.id == 'mangla_charan',
          orElse: () => audioSections.first,
        );
      case 'USTATI':
        return audioSections.firstWhere(
          (s) => s.id == 'ustati',
          orElse: () => audioSections.first,
        );
      case 'AMRIT_VANI':
        return audioSections.firstWhere(
          (s) => s.id == 'amrit_vani',
          orElse: () => audioSections.first,
        );
      case 'AARTI_SAHIB':
        return audioSections.firstWhere(
          (s) => s.id == 'aarti_roop_bhajan',
          orElse: () => audioSections.first,
        );
      case 'AARTI_SHIV_BHAJAN':
        return audioSections.firstWhere(
          (s) => s.id == 'aarti_shiv_bhajan',
          orElse: () => audioSections.first,
        );
      case 'AARTI_OM_JAI_JAGDISH':
        return audioSections.firstWhere(
          (s) => s.id == 'aarti_om_jai_jagdish',
          orElse: () => audioSections.first,
        );
      case 'PRARTHANA_JAI_SAMADHA':
        return audioSections.firstWhere(
          (s) => s.id == 'dhyan',
          orElse: () => audioSections.first,
        );
      case 'PRARTHANA':
        return audioSections.firstWhere(
          (s) => s.id == 'prarthana',
          orElse: () => audioSections.first,
        );
      default:
        return null;
    }
  }

  void _handlePlayPressed(
    AudioState audioState,
    AudioProviderNotifier audioNotifier,
  ) {
    if (audioState.isPlaying) {
      audioNotifier.pause();
    } else {
      final nativeSection =
          _sequence.items[_currentSequenceIndexNotifier.value];
      final audioSection = _mapNativeToAudioSection(nativeSection.id);

      // If we switched to a new section, and that section has valid timestamps, play it
      if (audioSection != null &&
          audioState.activeAudioSectionId != audioSection.id &&
          audioSection.isAvailable) {
        audioNotifier.playSection(audioSection, autoPlay: true);
      } else {
        // Otherwise, just resume playback
        audioNotifier.play();
      }
    }
  }

  void _toggleBookmark(int currentIndex) {
    setState(() {
      if (_bookmarkedAssetPage == currentIndex) {
        _bookmarkedAssetPage = null;
      } else {
        _bookmarkedAssetPage = currentIndex;
      }
    });
    // In a real app, save this to preferences
  }

  void _onPageChanged(int viewIndex) {
    if (_currentSequenceIndexNotifier.value == viewIndex) return;
    _accumulatedDownScroll = 0.0;
    _currentSequenceIndexNotifier.value = viewIndex;
    _saveLastPosition(viewIndex);
    _resetHideTimer();
  }

  void _onScrollUpdated(double width, double spacing) {
    if (_scrollDebounce?.isActive ?? false) return;
    _scrollDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || !_scrollController.hasClients) return;
      int bestIndex = _currentSequenceIndexNotifier.value;
      double bestDiff = double.infinity;

      final RenderObject? ancestorBox = _scrollController
          .position
          .context
          .storageContext
          .findRenderObject();
      if (ancestorBox == null) return;

      for (int i = 0; i < _sequence.items.length; i++) {
        final key = _itemKeys[i];
        if (key != null && key.currentContext != null) {
          final RenderBox? box =
              key.currentContext!.findRenderObject() as RenderBox?;
          if (box != null && box.attached) {
            final position = box.localToGlobal(
              Offset.zero,
              ancestor: ancestorBox,
            );
            final itemCenter = position.dy + box.size.height / 2;
            final viewportCenter =
                _scrollController.position.viewportDimension / 2;
            final diff = (itemCenter - viewportCenter).abs();
            if (diff < bestDiff) {
              bestDiff = diff;
              bestIndex = i;
            }
          }
        }
      }

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        bestIndex = _sequence.items.length - 1;
      }

      if (bestIndex != _currentSequenceIndexNotifier.value) {
        _currentSequenceIndexNotifier.value = bestIndex;
        _saveLastPosition(bestIndex);
      }
    });
  }

  void _showReaderOptions(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier settingsNotifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Material(
              color: isDark ? const Color(0xFF2A0D12) : const Color(0xFFFAF7F2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                side: BorderSide(color: AppTheme.cardBorder(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reader Preferences',
                            style: AppTheme.sheetTitle.copyWith(
                              color: isDark
                                  ? AppTheme.primaryIvory
                                  : AppTheme.darkBackground,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Reading Mode Selector
                      Text(
                        'Reading Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final currentMode = ref
                              .watch(settingsProvider)
                              .readingMode;
                          final isContinuous =
                              currentMode == ReadingMode.continuousScroll;

                          return Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (isContinuous) {
                                      settingsNotifier.setReadingMode(
                                        ReadingMode.pageSwipe,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isContinuous
                                          ? AppTheme.primaryGold.withValues(
                                              alpha: 0.18,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !isContinuous
                                            ? AppTheme.primaryGold
                                            : Theme.of(context).dividerColor
                                                  .withValues(alpha: 0.3),
                                        width: !isContinuous ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.auto_stories_rounded,
                                          size: 16,
                                          color: !isContinuous
                                              ? AppTheme.primaryGold
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Page Turn',
                                          style: TextStyle(
                                            fontWeight: !isContinuous
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 13,
                                            color: !isContinuous
                                                ? AppTheme.primaryGold
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!isContinuous) {
                                      settingsNotifier.setReadingMode(
                                        ReadingMode.continuousScroll,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isContinuous
                                          ? AppTheme.primaryGold.withValues(
                                              alpha: 0.18,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isContinuous
                                            ? AppTheme.primaryGold
                                            : Theme.of(context).dividerColor
                                                  .withValues(alpha: 0.3),
                                        width: isContinuous ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.swap_vert_rounded,
                                          size: 16,
                                          color: isContinuous
                                              ? AppTheme.primaryGold
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Continuous Scroll',
                                          style: TextStyle(
                                            fontWeight: isContinuous
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 13,
                                            color: isContinuous
                                                ? AppTheme.primaryGold
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Keep Screen Awake Toggle
                      Consumer(
                        builder: (context, ref, child) {
                          final currentKeepAwake = ref
                              .watch(settingsProvider)
                              .keepScreenAwake;
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppTheme.primaryGold,
                            activeTrackColor: AppTheme.primaryGold.withValues(
                              alpha: 0.38,
                            ),
                            title: const Text(
                              'Keep Screen Awake',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Prevents screen from turning off during paath',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AppTheme.primaryGold,
                                size: 20,
                              ),
                            ),
                            value: currentKeepAwake,
                            onChanged: (val) {
                              settingsNotifier.setKeepScreenAwake(val);
                              if (val) {
                                WakelockPlus.enable();
                              } else {
                                WakelockPlus.disable();
                              }
                            },
                          );
                        },
                      ),
                      const Divider(height: 24),

                      // 3. Text Size with Steppers
                      Consumer(
                        builder: (context, ref, child) {
                          final multiplier = ref
                              .watch(settingsProvider)
                              .fontSizeMultiplier;
                          final percentage = (multiplier * 100).round();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Text Size',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGold.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$percentage%',
                                      style: const TextStyle(
                                        color: AppTheme.primaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.text_decrease_rounded,
                                    ),
                                    tooltip: 'Decrease font size',
                                    onPressed: multiplier > 0.85
                                        ? () {
                                            final next = (multiplier - 0.15)
                                                .clamp(0.8, 1.4);
                                            settingsNotifier
                                                .setFontSizeMultiplier(
                                                  double.parse(
                                                    next.toStringAsFixed(2),
                                                  ),
                                                );
                                          }
                                        : null,
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppTheme.primaryGold,
                                        thumbColor: AppTheme.primaryGold,
                                        overlayColor: AppTheme.primaryGold
                                            .withValues(alpha: 0.2),
                                      ),
                                      child: Slider(
                                        value: multiplier,
                                        min: 0.8,
                                        max: 1.4,
                                        divisions: 4,
                                        onChanged: (val) {
                                          settingsNotifier
                                              .setFontSizeMultiplier(
                                                double.parse(
                                                  val.toStringAsFixed(2),
                                                ),
                                              );
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.text_increase_rounded,
                                    ),
                                    tooltip: 'Increase font size',
                                    onPressed: multiplier < 1.35
                                        ? () {
                                            final next = (multiplier + 0.15)
                                                .clamp(0.8, 1.4);
                                            settingsNotifier
                                                .setFontSizeMultiplier(
                                                  double.parse(
                                                    next.toStringAsFixed(2),
                                                  ),
                                                );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 24),

                      // 4. Language Selection
                      Text(
                        'Language',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final lang = ref
                              .watch(settingsProvider)
                              .selectedLanguage;
                          final remember = ref
                              .watch(settingsProvider)
                              .rememberLanguageChoice;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'سنڌي',
                                  style: TextStyle(
                                    fontFamily: AppTheme.sindhiRegularFont,
                                    fontSize: 20,
                                  ),
                                ),
                                trailing: lang == NativeLanguage.sindhi
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppTheme.primaryGold,
                                      )
                                    : null,
                                onTap: () => settingsNotifier.setNativeLanguage(
                                  NativeLanguage.sindhi,
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'हिन्दी',
                                  style: TextStyle(fontSize: 16),
                                ),
                                trailing: lang == NativeLanguage.hindi
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppTheme.primaryGold,
                                      )
                                    : null,
                                onTap: () => settingsNotifier.setNativeLanguage(
                                  NativeLanguage.hindi,
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Roman',
                                  style: TextStyle(fontSize: 16),
                                ),
                                trailing: lang == NativeLanguage.roman
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppTheme.primaryGold,
                                      )
                                    : null,
                                onTap: () => settingsNotifier.setNativeLanguage(
                                  NativeLanguage.roman,
                                ),
                              ),
                              const SizedBox(height: 6),
                              CheckboxListTile(
                                title: const Text(
                                  'Remember my language choice',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: remember,
                                activeColor: AppTheme.primaryGold,
                                onChanged: (val) => settingsNotifier
                                    .setRememberLanguageChoice(val ?? false),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
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
    final settings = ref.watch(settingsProvider);
    final activeLanguage = settings.selectedLanguage;
    final audioState = ref.watch(audioProvider);

    // Handle reading mode transition jumps or initial jump
    // Handle reading mode transition jumps or initial jump
    if (_lastReadingMode != settings.readingMode) {
      _needsScrollJump = true;
    }
    _lastReadingMode = settings.readingMode;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final isContinuous = settings.readingMode == ReadingMode.continuousScroll;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: activeLanguage != NativeLanguage.sindhi
          ? const ContentsDrawer()
          : null,
      endDrawer: activeLanguage == NativeLanguage.sindhi
          ? const ContentsDrawer()
          : null,
      body: Stack(
        children: [
          // 1. Base Layer
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (isContinuous) {
                  final double itemWidth = width - 4.0;

                  if (_needsScrollJump) {
                    _needsScrollJump = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        final key =
                            _itemKeys[_currentSequenceIndexNotifier.value];
                        if (key != null && key.currentContext != null) {
                          Scrollable.ensureVisible(
                            key.currentContext!,
                            alignment: 0.0,
                            duration: Duration.zero,
                          );
                        }
                      }
                    });
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo is ScrollUpdateNotification) {
                        if (scrollInfo.metrics.pixels > 150) {
                          ref
                              .read(genuineReadingProgressProvider.notifier)
                              .markGenuine();
                        }
                        _onScrollUpdated(itemWidth, 8.0);

                        // Immersive header logic: hide on scroll down 100px, show on scroll up 5px
                        if (scrollInfo.scrollDelta != null) {
                          if (scrollInfo.scrollDelta! > 0) {
                            _accumulatedDownScroll += scrollInfo.scrollDelta!;
                            if (_accumulatedDownScroll > 100 &&
                                _controlsVisibleNotifier.value) {
                              _controlsVisibleNotifier.value = false;
                            }
                          } else if (scrollInfo.scrollDelta! < 0) {
                            _accumulatedDownScroll = 0.0;
                            if (scrollInfo.scrollDelta! < -5 &&
                                !_controlsVisibleNotifier.value) {
                              _controlsVisibleNotifier.value = true;
                              _resetHideTimer();
                            }
                          }
                        }
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(_sequence.items.length, (
                          viewIndex,
                        ) {
                          final section = _sequence.items[viewIndex];
                          _itemKeys.putIfAbsent(viewIndex, () => GlobalKey());

                          return RepaintBoundary(
                            key: _itemKeys[viewIndex],
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: NativeSectionWidget(
                                section: section,
                                selectedLanguage: activeLanguage,
                                fontSizeMultiplier: settings.fontSizeMultiplier,
                                isContinuous: true,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                } else {
                  // Page Swipe
                  if (_needsScrollJump) {
                    _needsScrollJump = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(
                          _currentSequenceIndexNotifier.value,
                        );
                      }
                    });
                  }

                  return PageView.builder(
                    controller: _pageController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: _sequence.items.length,
                    itemBuilder: (context, viewIndex) {
                      final section = _sequence.items[viewIndex];
                      _itemKeys.putIfAbsent(viewIndex, () => GlobalKey());

                      return NotificationListener<ScrollUpdateNotification>(
                        onNotification:
                            (ScrollUpdateNotification notification) {
                              if (notification.metrics.pixels > 150) {
                                ref
                                    .read(
                                      genuineReadingProgressProvider.notifier,
                                    )
                                    .markGenuine();
                              }
                              if (notification.scrollDelta != null) {
                                if (notification.scrollDelta! > 0) {
                                  _accumulatedDownScroll +=
                                      notification.scrollDelta!;
                                  if (_accumulatedDownScroll > 100 &&
                                      _controlsVisibleNotifier.value) {
                                    _controlsVisibleNotifier.value = false;
                                  }
                                } else if (notification.scrollDelta! < 0) {
                                  _accumulatedDownScroll = 0.0;
                                  if (notification.scrollDelta! < -5 &&
                                      !_controlsVisibleNotifier.value) {
                                    _controlsVisibleNotifier.value = true;
                                    _resetHideTimer();
                                  }
                                }
                              }
                              return false;
                            },
                        child: GestureDetector(
                          onTap: _toggleControls,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            key: _itemKeys[viewIndex],
                            width: width,
                            child: RepaintBoundary(
                              child: NativeSectionWidget(
                                section: section,
                                selectedLanguage: activeLanguage,
                                fontSizeMultiplier: settings.fontSizeMultiplier,
                                isContinuous: false,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          // 2. Top Toolbar Overlay
          ValueListenableBuilder<bool>(
            valueListenable: _controlsVisibleNotifier,
            builder: (context, controlsVisible, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: controlsVisible
                    ? 0
                    : -(64 + MediaQuery.of(context).padding.top),
                left: 0,
                right: 0,
                child: child!,
              );
            },
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              height: 64 + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).appBarTheme.backgroundColor
                        ?.withValues(alpha: 0.95) ??
                    Colors.black.withValues(alpha: 0.95),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          // Leading Action (Drawer or Back)
                          if (activeLanguage != NativeLanguage.sindhi)
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: 'Contents Menu',
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Back',
                              onPressed: () => Navigator.pop(context),
                            ),

                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Directionality(
                                  textDirection:
                                      activeLanguage == NativeLanguage.sindhi
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: ValueListenableBuilder<int>(
                                    valueListenable:
                                        _currentSequenceIndexNotifier,
                                    builder: (context, currentIndex, _) {
                                      return Text(
                                        _getAppBarTitle(
                                          activeLanguage,
                                          currentIndex,
                                        ),
                                        style:
                                            activeLanguage ==
                                                NativeLanguage.sindhi
                                            ? const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    AppTheme.sindhiHeadingFont,
                                              )
                                            : AppTheme.appBarTitle.copyWith(
                                                color: Colors.white,
                                              ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reader Preferences Icon
                          IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Reader Preferences',
                            onPressed: () => _showReaderOptions(
                              context,
                              settings,
                              ref.read(settingsProvider.notifier),
                            ),
                          ),

                          // Bookmark Icon
                          ValueListenableBuilder<int>(
                            valueListenable: _currentSequenceIndexNotifier,
                            builder: (context, currentIndex, _) {
                              final isBookmarked =
                                  _bookmarkedAssetPage == currentIndex;
                              return IconButton(
                                icon: Icon(
                                  isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  color: isBookmarked
                                      ? AppTheme.primaryGold
                                      : Colors.white,
                                ),
                                tooltip: isBookmarked
                                    ? 'Remove Bookmark'
                                    : 'Add Bookmark',
                                onPressed: () => _toggleBookmark(currentIndex),
                              );
                            },
                          ),

                          // Trailing Action (Drawer or Back)
                          if (activeLanguage == NativeLanguage.sindhi)
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: 'Contents Menu',
                                onPressed: () =>
                                    Scaffold.of(ctx).openEndDrawer(),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Close Reader',
                              onPressed: () => Navigator.pop(context),
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _currentSequenceIndexNotifier,
                    builder: (context, currentIndex, _) {
                      return LinearProgressIndicator(
                        value: (currentIndex + 1) / _sequence.items.length,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: AppTheme.primaryGold,
                        minHeight: 2.5,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Page Swipe Navigation (Persistent)
          if (!isContinuous)
            Positioned.fill(
              child: ValueListenableBuilder<int>(
                valueListenable: _currentSequenceIndexNotifier,
                builder: (context, currentIndex, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Swipe Area Hint
                      Expanded(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedOpacity(
                              opacity: (_showSwipeHints && currentIndex > 0)
                                  ? 0.6
                                  : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  size: 40,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Next Swipe Area Hint
                      Expanded(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedOpacity(
                              opacity:
                                  (_showSwipeHints &&
                                      currentIndex <
                                          (_sequence.items.length - 1))
                                  ? 0.6
                                  : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 40,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // 3. Bottom Controls Overlay (Unified Audio + Auto Scroll)
          ValueListenableBuilder<bool>(
            valueListenable: _controlsVisibleNotifier,
            builder: (context, controlsVisible, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: controlsVisible
                    ? MediaQuery.of(context).padding.bottom
                    : -150,
                left: 0,
                right: 0,
                child: child!,
              );
            },
            child: ValueListenableBuilder<int>(
              valueListenable: _currentSequenceIndexNotifier,
              builder: (context, currentIndex, _) {
                final activeAudioSectionId = audioState.activeAudioSectionId;
                final isAudioPlaying = audioState.isPlaying;

                bool shouldShowSync = false;
                int targetIndex = currentIndex;
                String playingSectionTitle = '';

                if (isAudioPlaying) {
                  final indexInSequence = _sequence.items.indexWhere((s) {
                    final audioS = _mapNativeToAudioSection(s.id);
                    return audioS?.id == activeAudioSectionId;
                  });

                  if (indexInSequence != -1 &&
                      indexInSequence != currentIndex) {
                    shouldShowSync = true;
                    targetIndex = indexInSequence;
                    playingSectionTitle = _getAppBarTitle(
                      activeLanguage,
                      targetIndex,
                    );
                  }
                }

                final isDark = Theme.of(context).brightness == Brightness.dark;

                Widget? extraControls;
                if (shouldShowSync) {
                  extraControls = InkWell(
                    onTap: () {
                      if (isContinuous) {
                        final key = _itemKeys[targetIndex];
                        if (key != null && key.currentContext != null) {
                          Scrollable.ensureVisible(
                            key.currentContext!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      } else {
                        _pageController.animateToPage(
                          targetIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.primaryGold.withValues(alpha: 0.15)
                            : AppTheme.primaryGold.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: isDark
                                ? AppTheme.primaryGold
                                : AppTheme.deepBurgundy,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Playing: $playingSectionTitle — Tap to Sync Text',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.primaryIvory
                                    : AppTheme.deepBurgundy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: isDark
                                ? AppTheme.primaryGold
                                : AppTheme.deepBurgundy,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AudioMiniPlayer(
                      forceShow: true,
                      extraControls: extraControls,
                      onPlayPressed: () {
                        final audioNotifier = ref.read(audioProvider.notifier);
                        _handlePlayPressed(audioState, audioNotifier);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
