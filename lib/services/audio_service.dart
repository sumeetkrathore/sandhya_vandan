import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/audio_item.dart';

class AudioService {
  static const String _baseUrl = 'https://jaisamadha.com/wp-json/wp/v2';

  Future<File?> _getCacheFile(String key) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitized = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      return File('${dir.path}/audio_cache_$sanitized.json');
    } catch (_) {
      return null;
    }
  }

  /// Extracts pure JSON array by stripping any WordPress or Elementor injected HTML/CSS.
  String _sanitizeJson(String raw) {
    String body = raw.trim();
    final firstBracket = body.indexOf('[');
    final lastBracket = body.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      return body.substring(firstBracket, lastBracket + 1);
    }
    return body;
  }

  /// Fetches audio tracks from the WordPress REST API with local disk caching.
  Future<List<AudioItem>> fetchAudioTracks({
    dynamic categoryId = '153,200,201',
  }) async {
    final catParam = categoryId.toString();
    final cacheFile = await _getCacheFile(catParam);

    // 1. Try reading from disk cache first as a fast fallback
    List<AudioItem> cachedItems = [];
    if (cacheFile != null && await cacheFile.exists()) {
      try {
        final cachedRaw = await cacheFile.readAsString();
        if (cachedRaw.isNotEmpty) {
          final cleanJson = _sanitizeJson(cachedRaw);
          final List<dynamic> data = jsonDecode(cleanJson);
          final seenIds = <String>{};
          for (final raw in data) {
            if (raw is Map<String, dynamic>) {
              final item = AudioItem.fromJson(raw);
              if (item.audioUrl.isNotEmpty && seenIds.add(item.id)) {
                cachedItems.add(item);
              }
            }
          }
          debugPrint(
            'AudioService: Loaded ${cachedItems.length} items from cache for cat $catParam',
          );
        }
      } catch (e) {
        debugPrint('AudioService: Cache read error: $e');
      }
    }

    // 2. Fetch fresh items from WordPress REST API
    try {
      final uri = Uri.parse(
        '$_baseUrl/posts?categories=$catParam&per_page=50&_embed=1',
      );

      debugPrint('AudioService: Fetching $uri');

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      debugPrint(
        'AudioService: Response status ${response.statusCode} for cat $catParam',
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final cleanJson = _sanitizeJson(response.body);
        final List<dynamic> data = jsonDecode(cleanJson);

        final seenIds = <String>{};
        final items = <AudioItem>[];

        for (final raw in data) {
          if (raw is Map<String, dynamic>) {
            final item = AudioItem.fromJson(raw);
            if (item.audioUrl.isNotEmpty && seenIds.add(item.id)) {
              items.add(item);
            }
          }
        }

        // Cache the valid response to disk
        if (cacheFile != null && items.isNotEmpty) {
          cacheFile.writeAsString(response.body).catchError((err) {
            debugPrint('AudioService: Failed to write cache: $err');
            return cacheFile;
          });
        }

        debugPrint(
          'AudioService: Successfully fetched ${items.length} items for cat $catParam',
        );
        return items;
      }
    } catch (e) {
      debugPrint(
        'AudioService: Network error fetching tracks for $catParam: $e',
      );
    }

    // Return cached items if network fails, or empty list if no cache exists
    return cachedItems;
  }
}
