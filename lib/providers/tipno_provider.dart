import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tipno.dart';
import '../services/tipno_service.dart';
import '../providers/settings_provider.dart' show sharedPreferencesProvider;

final tipnoServiceProvider = Provider<TipnoService>((ref) {
  return TipnoService();
});

class TipnoNotifier extends AsyncNotifier<Tipno?> {
  static const String _cacheKey = 'cached_tipno';

  @override
  Future<Tipno?> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(tipnoServiceProvider);

    // 1. Load from cache
    Tipno? cached;
    try {
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        cached = Tipno.fromCache(jsonDecode(jsonString));
      }
    } catch (_) {}

    if (cached != null) {
      // 2. Fetch fresh data in background without awaiting
      _fetchLatest(service, prefs);
      return cached;
    }

    // No cache, fetch immediately
    return await _fetchLatest(service, prefs);
  }

  Future<Tipno?> _fetchLatest(
    TipnoService service,
    SharedPreferences prefs,
  ) async {
    try {
      final fresh = await service.fetchLatestTipno();
      if (fresh != null) {
        await prefs.setString(_cacheKey, jsonEncode(fresh.toCache()));
        state = AsyncData(fresh);
        return fresh;
      }
    } catch (e, st) {
      if (state.value == null) {
        state = AsyncError(e, st);
      }
    }
    return state.value;
  }
}

final tipnoProvider = AsyncNotifierProvider<TipnoNotifier, Tipno?>(() {
  return TipnoNotifier();
});
