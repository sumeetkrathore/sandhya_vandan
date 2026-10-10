import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/sandesh.dart';

class SandeshService {
  static const String _baseUrl = 'https://jaisamadha.com/wp-json/wp/v2';

  String _sanitizeJson(String raw) {
    final body = raw.trim();
    final firstBracket = body.indexOf('[');
    final lastBracket = body.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      return body.substring(firstBracket, lastBracket + 1);
    }
    final firstBrace = body.indexOf('{');
    final lastBrace = body.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return body.substring(firstBrace, lastBrace + 1);
    }
    return body;
  }

  /// Fetches the latest published Sandesh from the WordPress REST API.
  Future<Sandesh?> fetchLatestSandesh() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/posts?categories=117&per_page=1&orderby=date&order=desc&_embed=true',
      );

      log('Sandesh DEBUG: Fetching URI: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'SandyaVandanApp/1.0 (Android)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      log('Sandesh DEBUG: HTTP Status: ${response.statusCode}');
      log('Sandesh DEBUG: Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        log('Sandesh DEBUG: Response Body Length: ${response.body.length}');
        final cleanJson = _sanitizeJson(response.body);
        final List<dynamic> data = jsonDecode(cleanJson);
        log('Sandesh DEBUG: Parsed JSON array length: ${data.length}');
        if (data.isNotEmpty) {
          final s = Sandesh.fromJson(data.first);
          log('Sandesh DEBUG: Successfully created Sandesh object: id=${s.id}');
          return s;
        } else {
          log('Sandesh DEBUG: JSON array is empty');
        }
      } else {
        log('Failed to fetch Sandesh: HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      log('Error fetching Sandesh: $e, type: ${e.runtimeType}\n$st');
    }
    return null;
  }

  /// Fetches a specific post/Sandesh by its WordPress ID.
  Future<Sandesh?> fetchSandeshById(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/posts/$id?_embed=true');
      log('Sandesh DEBUG: Fetching post by ID: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'SandyaVandanApp/1.0 (Android)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final cleanJson = _sanitizeJson(response.body);
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        final s = Sandesh.fromJson(data);
        log('Sandesh DEBUG: Successfully fetched Sandesh by ID: id=${s.id}');
        return s;
      } else {
        log('Failed to fetch Sandesh by id $id: HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      log('Error fetching Sandesh by id $id: $e\n$st');
    }
    return null;
  }
}
