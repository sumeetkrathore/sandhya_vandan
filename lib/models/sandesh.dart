import '../utils/html_cleaner.dart';

class Sandesh {
  final int id;
  final String title;
  final String content; // The HTML cleaned content
  final DateTime date;
  final String permalink;
  final String? imageUrl;

  Sandesh({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.permalink,
    this.imageUrl,
  });

  /// True if the title represents an explicit celebration, festival, or event announcement.
  bool get hasEventTitle {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower == 'daily sandesh' ||
        lower == "today's sandesh" ||
        lower == 'sandesh') {
      return false;
    }
    // Filter out auto-generated generic date titles like "Sandesh | Oct, 5"
    if (RegExp(
      r'^sandesh\s*[\|\-:]\s*[a-zA-Z]+,?\s*\d+$',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }
    return true;
  }

  factory Sandesh.fromJson(Map<String, dynamic> json) {
    String? img;
    try {
      if (json['_embedded'] != null &&
          json['_embedded']['wp:featuredmedia'] is List) {
        final mediaList = json['_embedded']['wp:featuredmedia'] as List;
        if (mediaList.isNotEmpty && mediaList[0] is Map) {
          img = mediaList[0]['source_url'] as String?;
        }
      }
      if (img == null || img.isEmpty) {
        if (json['jetpack_featured_media_url'] is String &&
            (json['jetpack_featured_media_url'] as String).isNotEmpty) {
          img = json['jetpack_featured_media_url'] as String;
        }
      }
    } catch (_) {}

    return Sandesh(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: HtmlCleaner.clean(json['title']['rendered'] ?? ''),
      content: HtmlCleaner.clean(json['content']['rendered'] ?? ''),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      permalink: json['link'] ?? '',
      imageUrl: img,
    );
  }

  factory Sandesh.fromCache(Map<String, dynamic> json) {
    return Sandesh(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      permalink: json['permalink'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'permalink': permalink,
      'imageUrl': imageUrl,
    };
  }
}
