import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/native_text.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Initialized in main.dart
});

enum ReadingMode { pageSwipe, continuousScroll }

class SettingsState {
  final ThemeMode themeMode;
  final double fontSizeMultiplier;
  final List<String> bookmarks; // Stored as "collection|section|itemNumber"
  final String?
  lastReadingPosition; // Stored as "collection|section|scrollOffset"
  final ReadingMode readingMode;
  final NativeLanguage selectedLanguage;
  final bool rememberLanguageChoice;
  final bool hasShownLanguagePromptSession;
  final bool hasSeenOnboarding;
  final bool dailyNotificationsEnabled;
  final bool hasSeenRatingPrompt;
  final int appLaunchCount;
  final int reviewPromptCount;
  final String lastReviewPromptDate;
  final bool hasRatedApp;
  final String dailyReminderTime;
  final bool keepScreenAwake;
  final bool autoPlayAudio;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSizeMultiplier = 1.0,
    this.bookmarks = const [],
    this.lastReadingPosition,
    this.readingMode = ReadingMode.pageSwipe,
    this.selectedLanguage = NativeLanguage.sindhi,
    this.rememberLanguageChoice = false,
    this.hasShownLanguagePromptSession = false,
    this.hasSeenOnboarding = false,
    this.dailyNotificationsEnabled = true,
    this.hasSeenRatingPrompt = false,
    this.appLaunchCount = 0,
    this.reviewPromptCount = 0,
    this.lastReviewPromptDate = '',
    this.hasRatedApp = false,
    this.dailyReminderTime = '19:45',
    this.keepScreenAwake = true,
    this.autoPlayAudio = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSizeMultiplier,
    List<String>? bookmarks,
    String? lastReadingPosition,
    ReadingMode? readingMode,
    NativeLanguage? selectedLanguage,
    bool? rememberLanguageChoice,
    bool? hasShownLanguagePromptSession,
    bool? hasSeenOnboarding,
    bool? dailyNotificationsEnabled,
    bool? hasSeenRatingPrompt,
    int? appLaunchCount,
    int? reviewPromptCount,
    String? lastReviewPromptDate,
    bool? hasRatedApp,
    String? dailyReminderTime,
    bool? keepScreenAwake,
    bool? autoPlayAudio,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      bookmarks: bookmarks ?? this.bookmarks,
      lastReadingPosition: lastReadingPosition ?? this.lastReadingPosition,
      readingMode: readingMode ?? this.readingMode,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      rememberLanguageChoice:
          rememberLanguageChoice ?? this.rememberLanguageChoice,
      hasShownLanguagePromptSession:
          hasShownLanguagePromptSession ?? this.hasShownLanguagePromptSession,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      dailyNotificationsEnabled:
          dailyNotificationsEnabled ?? this.dailyNotificationsEnabled,
      hasSeenRatingPrompt: hasSeenRatingPrompt ?? this.hasSeenRatingPrompt,
      appLaunchCount: appLaunchCount ?? this.appLaunchCount,
      reviewPromptCount: reviewPromptCount ?? this.reviewPromptCount,
      lastReviewPromptDate: lastReviewPromptDate ?? this.lastReviewPromptDate,
      hasRatedApp: hasRatedApp ?? this.hasRatedApp,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _themeKey = 'themeMode';
  static const _fontSizeKey = 'fontSize';
  static const _bookmarksKey = 'bookmarks';
  static const _lastPositionKey = 'lastPosition';
  static const _readingModeKey = 'readingMode';
  static const _selectedLanguageKey = 'selectedLanguage';
  static const _rememberLanguageKey = 'rememberLanguageChoice';
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const _dailyNotificationsKey = 'dailyNotificationsEnabled';
  static const _hasSeenRatingPromptKey = 'hasSeenRatingPrompt';
  static const _appLaunchCountKey = 'appLaunchCount';
  static const _reviewPromptCountKey = 'reviewPromptCount';
  static const _lastReviewPromptDateKey = 'lastReviewPromptDate';
  static const _hasRatedAppKey = 'hasRatedApp';
  static const _dailyReminderTimeKey = 'dailyReminderTime';
  static const _keepScreenAwakeKey = 'keepScreenAwake';
  static const _autoPlayAudioKey = 'autoPlayAudio';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // Load from SharedPreferences
    final themeIndex = prefs.getInt(_themeKey);
    final themeMode = themeIndex != null
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;

    final fontSizeMultiplier = prefs.getDouble(_fontSizeKey) ?? 1.0;
    final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];
    final lastPosition = prefs.getString(_lastPositionKey);

    final readingModeIndex = prefs.getInt(_readingModeKey);
    final readingMode = readingModeIndex != null
        ? ReadingMode.values[readingModeIndex]
        : ReadingMode.pageSwipe;

    final languageIndex = prefs.getInt(_selectedLanguageKey);
    final selectedLanguage = languageIndex != null
        ? NativeLanguage.values[languageIndex]
        : NativeLanguage.sindhi;

    final rememberLanguageChoice = prefs.getBool(_rememberLanguageKey) ?? false;
    final keepScreenAwake = prefs.getBool(_keepScreenAwakeKey) ?? true;
    final autoPlayAudio = prefs.getBool(_autoPlayAudioKey) ?? false;

    return SettingsState(
      themeMode: themeMode,
      fontSizeMultiplier: fontSizeMultiplier,
      bookmarks: bookmarks,
      lastReadingPosition: lastPosition,
      readingMode: readingMode,
      selectedLanguage: selectedLanguage,
      rememberLanguageChoice: rememberLanguageChoice,
      hasSeenOnboarding: prefs.getBool(_hasSeenOnboardingKey) ?? false,
      dailyNotificationsEnabled: prefs.getBool(_dailyNotificationsKey) ?? true,
      hasSeenRatingPrompt: prefs.getBool(_hasSeenRatingPromptKey) ?? false,
      appLaunchCount: prefs.getInt(_appLaunchCountKey) ?? 0,
      reviewPromptCount: prefs.getInt(_reviewPromptCountKey) ?? 0,
      lastReviewPromptDate: prefs.getString(_lastReviewPromptDateKey) ?? '',
      hasRatedApp: prefs.getBool(_hasRatedAppKey) ?? false,
      dailyReminderTime: prefs.getString(_dailyReminderTimeKey) ?? '19:45',
      keepScreenAwake: keepScreenAwake,
      autoPlayAudio: autoPlayAudio,
    );
  }

  void setAutoPlayAudio(bool autoPlay) {
    state = state.copyWith(autoPlayAudio: autoPlay);
    ref.read(sharedPreferencesProvider).setBool(_autoPlayAudioKey, autoPlay);
  }

  void setKeepScreenAwake(bool keepAwake) {
    state = state.copyWith(keepScreenAwake: keepAwake);
    ref.read(sharedPreferencesProvider).setBool(_keepScreenAwakeKey, keepAwake);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(sharedPreferencesProvider).setInt(_themeKey, mode.index);
  }

  void setFontSizeMultiplier(double multiplier) {
    state = state.copyWith(fontSizeMultiplier: multiplier);
    ref.read(sharedPreferencesProvider).setDouble(_fontSizeKey, multiplier);
  }

  void toggleBookmark(String bookmarkId) {
    final newBookmarks = List<String>.from(state.bookmarks);
    if (newBookmarks.contains(bookmarkId)) {
      newBookmarks.remove(bookmarkId);
    } else {
      newBookmarks.add(bookmarkId);
    }
    state = state.copyWith(bookmarks: newBookmarks);
    ref
        .read(sharedPreferencesProvider)
        .setStringList(_bookmarksKey, newBookmarks);
  }

  void setLastReadingPosition(String position) {
    state = state.copyWith(lastReadingPosition: position);
    ref.read(sharedPreferencesProvider).setString(_lastPositionKey, position);
  }

  void setReadingMode(ReadingMode mode) {
    state = state.copyWith(readingMode: mode);
    ref.read(sharedPreferencesProvider).setInt(_readingModeKey, mode.index);
  }

  void setNativeLanguage(NativeLanguage language) {
    state = state.copyWith(selectedLanguage: language);
    if (state.rememberLanguageChoice) {
      ref
          .read(sharedPreferencesProvider)
          .setInt(_selectedLanguageKey, language.index);
    }
  }

  void setRememberLanguageChoice(bool remember) {
    state = state.copyWith(rememberLanguageChoice: remember);
    ref.read(sharedPreferencesProvider).setBool(_rememberLanguageKey, remember);
    if (remember) {
      ref
          .read(sharedPreferencesProvider)
          .setInt(_selectedLanguageKey, state.selectedLanguage.index);
    } else {
      ref.read(sharedPreferencesProvider).remove(_selectedLanguageKey);
    }
  }

  void markLanguagePromptShown() {
    state = state.copyWith(hasShownLanguagePromptSession: true);
  }

  void markOnboardingSeen() {
    state = state.copyWith(hasSeenOnboarding: true);
    ref.read(sharedPreferencesProvider).setBool(_hasSeenOnboardingKey, true);
  }

  void setDailyNotificationsEnabled(bool enabled) {
    state = state.copyWith(dailyNotificationsEnabled: enabled);
    ref
        .read(sharedPreferencesProvider)
        .setBool(_dailyNotificationsKey, enabled);
  }

  void setHasSeenRatingPrompt(bool value) {
    state = state.copyWith(hasSeenRatingPrompt: value);
    ref.read(sharedPreferencesProvider).setBool(_hasSeenRatingPromptKey, value);
  }

  void incrementAppLaunchCount() {
    final newCount = state.appLaunchCount + 1;
    state = state.copyWith(appLaunchCount: newCount);
    ref.read(sharedPreferencesProvider).setInt(_appLaunchCountKey, newCount);
  }

  void logReviewPromptShown() {
    final newCount = state.reviewPromptCount + 1;
    final nowString = DateTime.now().toIso8601String();
    state = state.copyWith(
      reviewPromptCount: newCount,
      lastReviewPromptDate: nowString,
    );
    ref.read(sharedPreferencesProvider).setInt(_reviewPromptCountKey, newCount);
    ref
        .read(sharedPreferencesProvider)
        .setString(_lastReviewPromptDateKey, nowString);
  }

  void setHasRatedApp() {
    state = state.copyWith(hasRatedApp: true);
    ref.read(sharedPreferencesProvider).setBool(_hasRatedAppKey, true);
  }

  void setDailyReminderTime(String time) {
    state = state.copyWith(dailyReminderTime: time);
    ref.read(sharedPreferencesProvider).setString(_dailyReminderTimeKey, time);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class LastReadAssetPageNotifier extends Notifier<int?> {
  static const _key = 'last_read_asset_page_v3';

  @override
  int? build() {
    final value = ref.watch(sharedPreferencesProvider).getInt(_key);
    if (value == null) return null;
    return value;
  }

  void updatePage(int page) {
    state = page;
    ref.read(sharedPreferencesProvider).setInt(_key, page);
  }
}

final lastReadAssetPageProvider =
    NotifierProvider<LastReadAssetPageNotifier, int?>(() {
      return LastReadAssetPageNotifier();
    });

class GenuineReadingProgressNotifier extends Notifier<bool> {
  static const _key = 'has_genuine_reading_progress';

  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  void markGenuine() {
    if (!state) {
      state = true;
      ref.read(sharedPreferencesProvider).setBool(_key, true);
    }
  }

  void reset() {
    if (state) {
      state = false;
      ref.read(sharedPreferencesProvider).setBool(_key, false);
    }
  }
}

final genuineReadingProgressProvider =
    NotifierProvider<GenuineReadingProgressNotifier, bool>(() {
      return GenuineReadingProgressNotifier();
    });
