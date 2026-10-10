import 'package:html/parser.dart' show parse;

class AudioItem {
  final String id;
  final String title;
  final String category; // 'sandhya_vandan', 'bhajans', etc.
  final String artist;
  final String description;
  final String coverImage;
  final String audioUrl;
  final String language;
  final int duration;
  final int order;
  final bool isPublished;
  final bool downloadEnabled;
  final String sourceType;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioItem({
    required this.id,
    required this.title,
    required this.category,
    required this.artist,
    required this.description,
    required this.coverImage,
    required this.audioUrl,
    required this.language,
    required this.duration,
    required this.order,
    required this.isPublished,
    required this.downloadEnabled,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Decodes HTML entities from WordPress titles
  static String _decodeHtml(String text) {
    final document = parse(text);
    return document.body?.text ?? text;
  }

  factory AudioItem.fromJson(Map<String, dynamic> json) {
    // Determine title
    String title = '';
    if (json['title'] is Map) {
      title = _decodeHtml(json['title']['rendered']?.toString() ?? '');
    } else {
      title = json['title']?.toString() ?? '';
    }

    // Determine description
    String description = '';
    if (json['content'] is Map) {
      description = _decodeHtml(json['content']['rendered']?.toString() ?? '');
    } else {
      description = json['description']?.toString() ?? '';
    }
    if (description.isEmpty && json['excerpt'] is Map) {
      description = _decodeHtml(json['excerpt']['rendered']?.toString() ?? '');
    }

    // Advanced Custom Fields (ACF) or JetEngine (jet_meta)
    final acf = json['acf'] as Map<String, dynamic>? ?? {};
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final jetMeta = json['jet_meta'] as Map<String, dynamic>? ?? {};

    // Safely extract field checking ACF, jet_meta, meta, and top level
    dynamic getField(String key) {
      return acf[key] ?? jetMeta[key] ?? meta[key] ?? json[key];
    }

    // Extract Cover Image from _embedded if available
    String coverImage = '';
    try {
      if (json['_embedded'] != null &&
          json['_embedded']['wp:featuredmedia'] != null) {
        final media = json['_embedded']['wp:featuredmedia'] as List;
        if (media.isNotEmpty && media[0]['source_url'] != null) {
          coverImage = media[0]['source_url'].toString();
        }
      }
    } catch (e) {
      // Ignored
    }

    String audioUrl =
        getField('r2_audio_url')?.toString() ??
        getField('audio_file')?.toString() ??
        '';
    if (audioUrl.isEmpty) {
      audioUrl =
          getField('wisdom_youtube_url')?.toString() ??
          getField('youtube_link')?.toString() ??
          '';
    }

    // Auto-generate YouTube high-quality thumbnail if coverImage is empty
    if (coverImage.isEmpty && audioUrl.contains('youtu')) {
      final match = RegExp(
        r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      ).firstMatch(audioUrl);
      if (match != null && match.groupCount >= 1) {
        coverImage =
            'https://img.youtube.com/vi/${match.group(1)}/hqdefault.jpg';
      }
    }

    return AudioItem(
      id: json['id']?.toString() ?? '',
      title: title,
      category: 'bhajans', // Defaulting to bhajans since we are fetching from Audio category
      artist: getField('wisdom_artist')?.toString() ?? 'Unknown Artist',
      description: description,
      coverImage: coverImage,
      audioUrl: audioUrl,
      language: getField('wisdom_language')?.toString() ?? 'Sindhi',
      duration:
          int.tryParse(getField('wisdom_duration')?.toString() ?? '0') ?? 0,
      order: int.tryParse(getField('app_order')?.toString() ?? '0') ?? 0,
      isPublished:
          true, // Assuming if it's returned by REST API, it is published
      downloadEnabled:
          getField('download_enabled') == true ||
          getField('download_enabled') == '1',
      sourceType:
          getField('source_type')?.toString() ??
          (audioUrl.contains('youtu') ? 'youtube' : 'cloudflare_r2'),
      createdAt:
          DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['modified']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
