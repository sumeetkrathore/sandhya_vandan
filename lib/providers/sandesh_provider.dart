import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sandesh.dart';
import '../services/sandesh_service.dart';

import '../providers/settings_provider.dart' show sharedPreferencesProvider;

final sandeshServiceProvider = Provider<SandeshService>((ref) {
  return SandeshService();
});

class SandeshNotifier extends AsyncNotifier<Sandesh?> {
  static const String _cacheKey = 'cached_sandesh';

  @override
  Future<Sandesh?> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(sandeshServiceProvider);

    // 1. Load from cache
    Sandesh? cached;
    try {
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        cached = Sandesh.fromCache(jsonDecode(jsonString));
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

  Future<Sandesh?> _fetchLatest(
    SandeshService service,
    SharedPreferences prefs,
  ) async {
    try {
      final fresh = await service.fetchLatestSandesh();
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

final sandeshProvider = AsyncNotifierProvider<SandeshNotifier, Sandesh?>(() {
  return SandeshNotifier();
});
