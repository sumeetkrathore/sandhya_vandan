import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/satguru.dart';
import '../services/satguru_service.dart';
import '../providers/settings_provider.dart' show sharedPreferencesProvider;

final satguruServiceProvider = Provider<SatguruService>((ref) {
  return SatguruService();
});

class SatguruNotifier extends AsyncNotifier<List<Satguru>> {
  static const String _cacheKey = 'cached_satgurus_v2';

  @override
  Future<List<Satguru>> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = ref.watch(satguruServiceProvider);

    // 1. Load from cache
    List<Satguru>? cached;
    try {
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        cached = decoded.map((e) => Satguru.fromJson(e)).toList();
      }
    } catch (_) {}

    if (cached != null && cached.isNotEmpty) {
      // 2. Fetch fresh data in background without awaiting
      _fetchLatest(service, prefs);
      return cached;
    }

    // No cache, fetch immediately
    return await _fetchLatest(service, prefs) ?? [];
  }

  Future<List<Satguru>?> _fetchLatest(
    SatguruService service,
    SharedPreferences prefs,
  ) async {
    try {
      final fresh = await service.fetchSatgurus();
      if (fresh.isNotEmpty) {
        final List<Map<String, dynamic>> cacheData = fresh
            .map((s) => s.toJson())
            .toList();
        await prefs.setString(_cacheKey, jsonEncode(cacheData));
        state = AsyncData(fresh);
        return fresh;
      }
    } catch (e, st) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncError(e, st);
      }
    }
    return state.value;
  }
}

final satguruProvider = AsyncNotifierProvider<SatguruNotifier, List<Satguru>>(
  () {
    return SatguruNotifier();
  },
);

final satguruBiographyProvider = FutureProvider.family<Satguru, String>((
  ref,
  slug,
) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = ref.watch(satguruServiceProvider);
  final cacheKey = 'satguru_biography_v4_$slug';

  try {
    // 1. Fetch fresh from network first
    final fresh = await service.fetchSatguruBySlug(slug);
    if (fresh != null) {
      assert(fresh.slug == slug, 'Returned slug must match requested slug');
      if (fresh.slug != slug) {
        throw StateError(
          'Satguru identity mismatch: requested $slug, received ${fresh.slug}',
        );
      }
      debugPrint('Loaded fresh biography for $slug (Title: ${fresh.title})');
      await prefs.setString(cacheKey, jsonEncode(fresh.toJson()));
      return fresh;
    }
  } catch (e) {
    debugPrint('Network fetch failed for $slug: $e');
  }

  // 2. Fallback to cache if network fails
  try {
    final jsonString = prefs.getString(cacheKey);
    if (jsonString != null) {
      final cached = Satguru.fromJson(jsonDecode(jsonString));
      if (cached.slug == slug) {
        debugPrint(
          'Loaded cached biography for $slug (Title: ${cached.title})',
        );
        return cached;
      } else {
        debugPrint('Cache slug mismatch, ignoring cache for $slug');
      }
    }
  } catch (_) {}

  throw Exception(
    'Could not load Satguru: $slug (Both network and cache failed)',
  );
});
