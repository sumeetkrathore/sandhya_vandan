import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/tipno.dart';

class TipnoService {
  static const String _baseUrl = 'https://jaisamadha.com/wp-json/wp/v2';

  String _sanitizeJson(String raw) {
    final body = raw.trim();
    final firstBracket = body.indexOf('[');
    final lastBracket = body.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      return body.substring(firstBracket, lastBracket + 1);
    }
    return body;
  }

  /// Fetches the latest published Tipno from the WordPress REST API.
  Future<Tipno?> fetchLatestTipno() async {
    try {
      final uri = Uri.parse('$_baseUrl/tipno').replace(
        queryParameters: {
          'per_page': '1',
          'orderby': 'date',
          'order': 'desc',
          '_fields': 'id,date,link,title,content',
        },
      );

      log('Tipno DEBUG: Fetching URI: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      log('Tipno DEBUG: HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final cleanJson = _sanitizeJson(response.body);
        final List<dynamic> data = jsonDecode(cleanJson);
        if (data.isNotEmpty) {
          final t = Tipno.fromJson(data.first);
          return t;
        }
      } else {
        log('Failed to fetch Tipno: HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      log('Error fetching Tipno: $e, type: ${e.runtimeType}\n$st');
    }
    return null;
  }
}
