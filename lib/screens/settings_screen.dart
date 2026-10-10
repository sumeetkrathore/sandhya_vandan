import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';

import 'dart:convert';
import 'dart:io';

import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../models/native_text.dart';
import 'onboarding_screen.dart';
import '../services/notification_service.dart';
import '../services/download_service.dart';
import '../widgets/frosted_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';
  int _audioBytes = 0;
  int _audioCount = 0;
  int _tempBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadStorageStats();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  Future<void> _loadStorageStats() async {
    final downloadService = ref.read(downloadServiceProvider);
    final audioBytes = await downloadService.getDownloadedAudioSize();
    final audioCount = await downloadService.getDownloadedAudioCount();
    final tempBytes = await downloadService.getTempCacheSize();
    if (mounted) {
      setState(() {
        _audioBytes = audioBytes;
        _audioCount = audioCount;
        _tempBytes = tempBytes;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _confirmClearDownloads() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Downloaded Audio?'),
        content: const Text(
          'This will remove all downloaded audio tracks from your device. You can download them again anytime with an internet connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(downloadServiceProvider).clearAllDownloadedAudio();
              await _loadStorageStats();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloaded audio removed.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Free Up Cache?'),
        content: const Text(
          'This will clear temporarily cached images and network files. Your bookmarks and saved preferences will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(downloadServiceProvider).clearTempCache();
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              await _loadStorageStats();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache freed successfully.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Free Up'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  String _getLanguageName(NativeLanguage lang) {
    switch (lang) {
      case NativeLanguage.sindhi:
        return 'سنڌي';
      case NativeLanguage.roman:
        return 'Roman';
      case NativeLanguage.hindi:
        return 'हिन्दी';
    }
  }

  String _getReadingModeName(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.pageSwipe:
        return 'Page Swipe';
      case ReadingMode.continuousScroll:
        return 'Continuous Scroll';
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showSelectionSheet({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...children,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppTheme.cardBorder(context)
                .withValues(alpha: isDark ? 0.35 : 0.55),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark ? AppTheme.primaryGold : const Color(0xFF76534A),
        ),
      ),
    );
  }

  Widget _buildIconBadge(BuildContext context, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(child: Icon(icon, size: 18, color: AppTheme.primaryGold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    ref.listen(downloadSyncProvider, (prev, next) => _loadStorageStats());

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Settings'),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ---------------------------------------------------------
            // READING PREFERENCES CARD
            // ---------------------------------------------------------
            _buildCard(context, [
              _buildHeader(context, 'Reading Experience'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.language_rounded),
                title: Text(
                  'Language',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getLanguageName(settings.selectedLanguage),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  _showSelectionSheet(
                    context: context,
                    title: 'Select Language',
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('سنڌي'),
                        trailing:
                            settings.selectedLanguage == NativeLanguage.sindhi
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setNativeLanguage(NativeLanguage.sindhi);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('Roman'),
                        trailing:
                            settings.selectedLanguage == NativeLanguage.roman
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setNativeLanguage(NativeLanguage.roman);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('हिन्दी'),
                        trailing:
                            settings.selectedLanguage == NativeLanguage.hindi
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setNativeLanguage(NativeLanguage.hindi);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      Consumer(
                        builder: (context, ref, child) {
                          final sheetSettings = ref.watch(settingsProvider);
                          return SwitchListTile(
                            title: Text(
                              'Remember my choice',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Skip the language popup on next start',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            value: sheetSettings.rememberLanguageChoice,
                            onChanged: (bool value) => ref
                                .read(settingsProvider.notifier)
                                .setRememberLanguageChoice(value),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.menu_book_rounded),
                title: Text(
                  'Scroll Style',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getReadingModeName(settings.readingMode),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  _showSelectionSheet(
                    context: context,
                    title: 'Scroll Style',
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('Page Swipe'),
                        trailing: settings.readingMode == ReadingMode.pageSwipe
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setReadingMode(ReadingMode.pageSwipe);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('Continuous Scroll'),
                        trailing:
                            settings.readingMode == ReadingMode.continuousScroll
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setReadingMode(ReadingMode.continuousScroll);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              SwitchListTile(
                activeThumbColor: AppTheme.primaryGold,
                activeTrackColor: AppTheme.primaryGold.withValues(alpha: 0.38),
                secondary: _buildIconBadge(context, Icons.light_mode_outlined),
                title: Text(
                  'Keep Screen Awake',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Prevents device screen from turning off during Paath',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                value: settings.keepScreenAwake,
                onChanged: (bool value) {
                  notifier.setKeepScreenAwake(value);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              SwitchListTile(
                activeThumbColor: AppTheme.primaryGold,
                activeTrackColor: AppTheme.primaryGold.withValues(alpha: 0.38),
                secondary: _buildIconBadge(
                  context,
                  Icons.play_circle_outline_rounded,
                ),
                title: Text(
                  'Auto-Play Audio in Reader Mode',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Automatically start playing audio when opening Paath or Reader',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                value: settings.autoPlayAudio,
                onChanged: (bool value) {
                  notifier.setAutoPlayAudio(value);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
              ),
              const SizedBox(height: 4),
            ]),

            // ---------------------------------------------------------
            // APP PREFERENCES CARD
            // ---------------------------------------------------------
            _buildCard(context, [
              _buildHeader(context, 'App Settings'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.dark_mode_outlined),
                title: Text(
                  'Appearance',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getThemeName(settings.themeMode),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  _showSelectionSheet(
                    context: context,
                    title: 'Appearance',
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('System Default'),
                        trailing: settings.themeMode == ThemeMode.system
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setThemeMode(ThemeMode.system);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('Light'),
                        trailing: settings.themeMode == ThemeMode.light
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setThemeMode(ThemeMode.light);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        title: const Text('Dark'),
                        trailing: settings.themeMode == ThemeMode.dark
                            ? Icon(Icons.check, color: AppTheme.primaryGold)
                            : null,
                        onTap: () {
                          notifier.setThemeMode(ThemeMode.dark);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              SwitchListTile(
                activeThumbColor: AppTheme.primaryGold,
                activeTrackColor: AppTheme.primaryGold.withValues(alpha: 0.38),
                secondary: _buildIconBadge(
                  context,
                  Icons.notifications_active_outlined,
                ),
                title: Text(
                  'Daily Reminders & Wisdom',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  "Receive Satguru's daily Sandesh in the morning and a Sandhya Vandan reminder in the evening",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                value: settings.dailyNotificationsEnabled,
                onChanged: (bool value) async {
                  if (value) {
                    final service = NotificationService();
                    final granted = await service.requestPermissions();
                    if (granted) {
                      notifier.setDailyNotificationsEnabled(true);
                      service.scheduleSandhyaReminder();
                      await service.showTestNotification();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification permission denied.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    notifier.setDailyNotificationsEnabled(false);
                    NotificationService().cancelAllNotifications();
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
              ),
              if (settings.dailyNotificationsEnabled) ...[
                const Divider(height: 1, indent: 62, thickness: 0.5),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                  leading: _buildIconBadge(
                    context,
                    Icons.notification_add_outlined,
                  ),
                  title: Text(
                    'Send Test Notification',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Test how daily reminders look on your status bar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  ),
                  onTap: () async {
                    final service = NotificationService();
                    final granted = await service.requestPermissions();
                    if (granted) {
                      await service.showTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Test notification sent! Check your status bar.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification permission denied.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 4),
            ]),

            // ---------------------------------------------------------
            // STORAGE & OFFLINE CONTENT CARD
            // ---------------------------------------------------------
            _buildCard(context, [
              _buildHeader(context, 'Storage & Offline Content'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.download_done_rounded),
                title: Text(
                  'Downloaded Audio',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _audioCount == 0
                      ? 'No audio tracks downloaded offline'
                      : '$_audioCount ${_audioCount == 1 ? "track" : "tracks"} (${_formatBytes(_audioBytes)})',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
                trailing: _audioCount > 0
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error
                                .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          minimumSize: const Size(56, 30),
                        ),
                        onPressed: _confirmClearDownloads,
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      )
                    : null,
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(
                  context,
                  Icons.cleaning_services_rounded,
                ),
                title: Text(
                  'Temporary Cache',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Cached images and app files (${_formatBytes(_tempBytes)})',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
                trailing: _tempBytes > 0
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGold,
                          side: BorderSide(
                            color: AppTheme.primaryGold.withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          minimumSize: const Size(56, 30),
                        ),
                        onPressed: _confirmClearCache,
                        child: const Text(
                          'Free Up',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
            ]),

            // ---------------------------------------------------------
            // HELP & SUPPORT CARD
            // ---------------------------------------------------------
            _buildCard(context, [
              _buildHeader(context, 'Help & Support'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.help_outline_rounded),
                title: Text(
                  'App Tutorial',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.star_rate_rounded),
                title: Text(
                  'Rate the App',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () async {
                  ref.read(settingsProvider.notifier).setHasRatedApp();
                  try {
                    final InAppReview inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      await inAppReview.openStoreListing();
                    } else {
                      final url = Uri.parse(
                        'market://details?id=com.jaisamadha.sandyavandan',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        await launchUrl(
                          Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.jaisamadha.sandyavandan',
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please restart the app to enable Ratings.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.feedback_outlined),
                title: Text(
                  'Send Feedback',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _SendFeedbackScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.mail_outline_rounded),
                title: Text(
                  'Email Us',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'support@jaisamadha.com',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@jaisamadha.com',
                    queryParameters: {
                      'subject': 'Sandhya Vandan – Query / Suggestion',
                    },
                  );
                  try {
                    await launchUrl(
                      emailUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    debugPrint('Could not launch email: $e');
                  }
                },
              ),
              const SizedBox(height: 4),
            ]),

            // ---------------------------------------------------------
            // OFFICIAL COMMUNITY & WEBSITE CARD
            // ---------------------------------------------------------
            _buildCard(context, [
              _buildHeader(context, 'Official Community'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0),
                leading: _buildIconBadge(context, Icons.public_rounded),
                title: Text(
                  'Official Website',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'www.jaisamadha.com',
                  style: TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => _launchUrl('https://jaisamadha.com'),
              ),
              const Divider(height: 1, indent: 62, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'STAY CONNECTED WITH ASHRAM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.primaryGold.withValues(alpha: 0.85)
                        : const Color(0xFF76534A),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSocialChip(
                        context: context,
                        label: 'Facebook',
                        icon: const FaIcon(
                          FontAwesomeIcons.facebook,
                          size: 20,
                          color: Color(0xFF1877F2),
                        ),
                        url: 'https://www.facebook.com/SamadhaAashram',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSocialChip(
                        context: context,
                        label: 'Instagram',
                        icon: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFf09433),
                              Color(0xFFe6683c),
                              Color(0xFFdc2743),
                              Color(0xFFcc2366),
                              Color(0xFFbc1888),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ).createShader(bounds),
                          child: const FaIcon(
                            FontAwesomeIcons.instagram,
                            size: 20,
                          ),
                        ),
                        url: 'https://www.instagram.com/samadha.aashram/',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSocialChip(
                        context: context,
                        label: 'YouTube',
                        icon: const FaIcon(
                          FontAwesomeIcons.youtube,
                          size: 20,
                          color: Color(0xFFFF0000),
                        ),
                        url: 'https://www.youtube.com/@Samadha.Aashram',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSocialChip(
                        context: context,
                        label: 'TikTok',
                        icon: FaIcon(
                          FontAwesomeIcons.tiktok,
                          size: 19,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        url: 'https://www.tiktok.com/@samadha.ashram',
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            // ---------------------------------------------------------
            // MINIMALIST ELEGANT FOOTER
            // ---------------------------------------------------------
            const SizedBox(height: 12),
            Column(
              children: [
                Text(
                  'Official Samadha Ashram App',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Developed by Sumeet Rathore',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.55),
                  ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'v$_version${_buildNumber.isNotEmpty ? ' (Build $_buildNumber)' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.40),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialChip({
    required BuildContext context,
    required String label,
    required Widget icon,
    required String url,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendFeedbackScreen extends StatefulWidget {
  const _SendFeedbackScreen();

  @override
  State<_SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<_SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedType = 'Suggestion';
  bool _isSubmitting = false;

  final List<String> _types = [
    'Suggestion',
    'Content Correction',
    'Technical Issue',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('jaisamadha.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection is required to submit feedback.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final payload = {
        'type': _selectedType,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'message': _messageController.text.trim(),
        'appVersion': packageInfo.version,
        'platform': 'Android',
      };

      final response = await http.post(
        Uri.parse('https://jaisamadha.com/wp-json/fluentform/v1/app-feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Jai Samadha!'),
            content: const Text('Thank you\nYour feedback has been received.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to send feedback.\nPlease check your connection and try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to send feedback.\nPlease check your connection and try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Feedback Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedType = v);
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text(
                            'Submit Feedback',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
