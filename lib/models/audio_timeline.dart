class AudioTimeline {
  final String masterAudioId;
  final String assetPath;
  final int totalDurationMs;
  final List<AudioSegment> segments;

  AudioTimeline({
    required this.masterAudioId,
    required this.assetPath,
    required this.totalDurationMs,
    required this.segments,
  });

  factory AudioTimeline.fromJson(Map<String, dynamic> json) {
    return AudioTimeline(
      masterAudioId: json['masterAudioId'] ?? '',
      assetPath: json['assetPath'] ?? '',
      totalDurationMs: json['totalDurationMs'] ?? 0,
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((item) => AudioSegment.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class AudioSegment {
  final String id;
  final String title;
  final String type;
  final int pustakPage;
  final int? audioStartMs;
  final int? audioEndMs;

  AudioSegment({
    required this.id,
    required this.title,
    required this.type,
    required this.pustakPage,
    this.audioStartMs,
    this.audioEndMs,
  });

  factory AudioSegment.fromJson(Map<String, dynamic> json) {
    return AudioSegment(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'recitation',
      pustakPage: json['pustakPage'] ?? 0,
      audioStartMs: json['audioStartMs'],
      audioEndMs: json['audioEndMs'],
    );
  }
}
