import '../utils/html_cleaner.dart';

class Tipno {
  final int id;
  final String title;
  final String content; // The HTML cleaned content
  final DateTime date;
  final String permalink;

  Tipno({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.permalink,
  });

  factory Tipno.fromJson(Map<String, dynamic> json) {
    return Tipno(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: HtmlCleaner.clean(json['title']['rendered'] ?? ''),
      content: HtmlCleaner.clean(json['content']['rendered'] ?? ''),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      permalink: json['link'] ?? '',
    );
  }

  factory Tipno.fromCache(Map<String, dynamic> json) {
    return Tipno(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      permalink: json['permalink'] as String,
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'permalink': permalink,
    };
  }
}
