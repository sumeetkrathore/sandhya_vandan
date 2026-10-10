import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/satguru.dart';

class SatguruService {
  static const String endpoint =
      'https://jaisamadha.com/wp-json/wp/v2/sant-satguru?_embed=1&per_page=10';

  String _sanitizeJson(String raw) {
    String body = raw.trim();
    final firstBracket = body.indexOf('[');
    final lastBracket = body.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      return body.substring(firstBracket, lastBracket + 1);
    }
    return body;
  }

  Future<List<Satguru>> fetchSatgurus() async {
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final cleanJson = _sanitizeJson(response.body);
      final List<dynamic> jsonList = jsonDecode(cleanJson);
      final List<Satguru> rawList = jsonList
          .map((json) => Satguru.fromJson(json))
          .toList();

      // Ensure proper lineage order explicitly
      final orderMap = {
        'satguru-baba-har-bhajan-sahib': 1,
        'satguru-baba-ram-bhajan-sahib': 2,
        'satguru-baba-roop-bhajan-sahib': 3,
        'satguru-baba-kishan-bhajan-sahib': 4,
        'satguru-baba-gobind-bhajan-sahib': 5,
        'satguru-baba-shiv-bhajan-sahib': 6,
        'satguru-baba-narayan-bhajan-sahib': 7,
      };

      rawList.sort((a, b) {
        final orderA = orderMap[a.slug] ?? 999;
        final orderB = orderMap[b.slug] ?? 999;
        return orderA.compareTo(orderB);
      });

      return rawList;
    } else {
      throw Exception('Failed to load Satgurus: ${response.statusCode}');
    }
  }

  Future<Satguru?> fetchSatguruBySlug(String slug) async {
    final slugEndpoint =
        'https://jaisamadha.com/wp-json/wp/v2/sant-satguru?_embed=1&slug=$slug';
    final response = await http.get(Uri.parse(slugEndpoint));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      if (jsonList.isNotEmpty) {
        return Satguru.fromJson(jsonList.first);
      }
      return null;
    } else {
      throw Exception('Failed to load Satguru $slug: ${response.statusCode}');
    }
  }
}
