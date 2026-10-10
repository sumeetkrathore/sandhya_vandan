import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification_update.dart';

class NotificationsService {
  final String baseUrl = 'https://jaisamadha.com/wp-json/jaisamadha/v1';

  Future<List<NotificationUpdate>> fetchLatestUpdates() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/updates'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationUpdate.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load updates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
