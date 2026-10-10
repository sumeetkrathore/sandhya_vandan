import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/ashram.dart';

class AshramService {
  static const String _baseUrl = 'https://jaisamadha.com/wp-json/wp/v2';
  static const String _cacheFileName = 'ashrams_cache.json';

  Future<File?> _getCacheFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_cacheFileName');
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

  List<Ashram> _parseList(dynamic decoded) {
    if (decoded is! List) return [];
    final List<Ashram> items = [];
    for (final raw in decoded) {
      if (raw is Map<String, dynamic>) {
        try {
          items.add(Ashram.fromJson(raw));
        } catch (e) {
          debugPrint('AshramService: Error parsing ashram item: $e');
        }
      }
    }
    return items;
  }

  Future<List<Ashram>> fetchAshrams() async {
    final cacheFile = await _getCacheFile();

    // 1. Try reading from disk cache first as fast fallback
    List<Ashram> cachedAshrams = [];
    if (cacheFile != null && await cacheFile.exists()) {
      try {
        final cachedRaw = await cacheFile.readAsString();
        if (cachedRaw.isNotEmpty) {
          final cleanJson = _sanitizeJson(cachedRaw);
          final decoded = json.decode(cleanJson);
          cachedAshrams = _parseList(decoded);
          if (cachedAshrams.isNotEmpty) {
            debugPrint(
              'AshramService: Loaded ${cachedAshrams.length} ashrams from local cache',
            );
          }
        }
      } catch (e) {
        debugPrint('AshramService: Error reading cache: $e');
      }
    }

    // 2. Fetch fresh from REST API
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/ashrams?_embed&per_page=100'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final cleanJson = _sanitizeJson(response.body);
        final decoded = json.decode(cleanJson);
        final freshItems = _parseList(decoded);

        if (freshItems.isNotEmpty) {
          // Write to local cache asynchronously
          if (cacheFile != null) {
            cacheFile.writeAsString(cleanJson).catchError((_) => cacheFile);
          }
          return freshItems;
        }
      }
    } catch (e) {
      debugPrint('AshramService: Network fetch failed: $e');
    }

    // 3. Fallback to cached items if network fails
    if (cachedAshrams.isNotEmpty) {
      return cachedAshrams;
    }

    throw Exception(
      'Unable to load ashrams. Please check your internet connection.',
    );
  }
}
