import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_update.dart';
import '../services/notifications_service.dart';
import 'settings_provider.dart' show sharedPreferencesProvider;

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

class NotificationsNotifier extends AsyncNotifier<List<NotificationUpdate>> {
  static const String _cacheKey = 'cached_notifications_updates';

  @override
  Future<List<NotificationUpdate>> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(notificationsServiceProvider);

    // 1. Load from cache immediately for fast UI
    List<NotificationUpdate>? cached;
    try {
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        cached = decoded.map((e) => NotificationUpdate.fromJson(e)).toList();
      }
    } catch (_) {}

    if (cached != null && cached.isNotEmpty) {
      // 2. Fetch fresh data in background without awaiting so UI shows cache
      _fetchLatest(service, prefs);
      return cached;
    }

    // No cache, fetch immediately
    return await _fetchLatest(service, prefs);
  }

  Future<List<NotificationUpdate>> _fetchLatest(
    NotificationsService service,
    SharedPreferences prefs,
  ) async {
    try {
      final fresh = await service.fetchLatestUpdates();
      if (fresh.isNotEmpty) {
        final encoded = fresh.map((e) => e.toJson()).toList();
        await prefs.setString(_cacheKey, jsonEncode(encoded));
        state = AsyncData(fresh);
        return fresh;
      }
    } catch (e, st) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncError(e, st);
      }
    }
    return state.value ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(notificationsServiceProvider);
    await _fetchLatest(service, prefs);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationUpdate>>(() {
      return NotificationsNotifier();
    });
