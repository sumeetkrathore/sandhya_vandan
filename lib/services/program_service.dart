import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/program.dart';
import 'notification_service.dart';

class ProgramService {
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

  Future<List<Program>> fetchUpcomingPrograms() async {
    try {
      final uri = Uri.parse('$_baseUrl/upcoming_programs').replace(
        queryParameters: {'per_page': '10', 'orderby': 'date', 'order': 'desc'},
      );

      log('Program DEBUG: Fetching URI: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      log('Program DEBUG: HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final cleanJson = _sanitizeJson(response.body);
        final List<dynamic> data = jsonDecode(cleanJson);
        log('Program DEBUG: Parsed JSON array length: ${data.length}');

        final programs = data.map((json) => Program.fromJson(json)).toList();

        // Sort: Ongoing first, then upcoming (closest first), then past
        programs.sort((a, b) {
          int priority(Program p) => p.isOngoing ? 0 : (p.isUpcoming ? 1 : 2);
          final pA = priority(a);
          final pB = priority(b);
          if (pA != pB) return pA.compareTo(pB);

          // Within same bucket, sort by date
          if (a.startDate.isEmpty && b.startDate.isEmpty) return 0;
          if (a.startDate.isEmpty) return 1;
          if (b.startDate.isEmpty) return -1;

          try {
            final dateA = DateTime.parse(a.startDate);
            final dateB = DateTime.parse(b.startDate);
            return dateA.compareTo(dateB);
          } catch (_) {
            return 0;
          }
        });

        // Automatically schedule local event reminders for fetched programs
        NotificationService().scheduleEventReminders(programs);

        return programs;
      } else {
        log('Failed to fetch Programs: HTTP ${response.statusCode}');
      }
    } catch (e, st) {
      log('Error fetching Programs: $e\n$st');
    }
    return [];
  }
}
