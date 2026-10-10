class Composition {
  final String collection;
  final String section;
  final String languageScript;
  final String status;
  final List<int> sourcePdfPages;
  final List<CompositionSection> items;

  // Audio fields for future support
  final String? masterAudioId;
  final int? totalDurationMs;

  Composition({
    required this.collection,
    required this.section,
    required this.languageScript,
    required this.status,
    required this.sourcePdfPages,
    required this.items,
    this.masterAudioId,
    this.totalDurationMs,
  });

  factory Composition.fromJson(Map<String, dynamic> json) {
    return Composition(
      collection: json['collection'] ?? '',
      section: json['section'] ?? '',
      languageScript: json['language_script'] ?? '',
      status: json['status'] ?? '',
      sourcePdfPages:
          (json['source_pdf_pages'] as List<dynamic>?)?.cast<int>() ?? [],
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => CompositionSection.fromJson(item))
              .toList() ??
          [],
      masterAudioId: json['masterAudioId'],
      totalDurationMs: json['totalDurationMs'],
    );
  }
}

class CompositionSection {
  final int number;
  final int sourcePdfPage;
  final List<TimelineSegment> segments;

  // Audio fields for future support
  final int? audioStartMs;
  final int? audioEndMs;

  CompositionSection({
    required this.number,
    required this.sourcePdfPage,
    required this.segments,
    this.audioStartMs,
    this.audioEndMs,
  });

  factory CompositionSection.fromJson(Map<String, dynamic> json) {
    List<TimelineSegment> parsedSegments = [];

    // Check if we have the current pilot structure (list of strings in "lines")
    if (json.containsKey('lines')) {
      final lines = (json['lines'] as List<dynamic>).cast<String>();
      // We wrap the raw lines in recitation segments for future-proofing
      for (var line in lines) {
        parsedSegments.add(TimelineSegment(type: 'recitation', text: line));
      }
    }
    // Future proofing for actual segments array if they move to it later
    else if (json.containsKey('segments')) {
      parsedSegments = (json['segments'] as List<dynamic>)
          .map((s) => TimelineSegment.fromJson(s))
          .toList();
    }

    return CompositionSection(
      number: json['number'] ?? 0,
      sourcePdfPage: json['source_pdf_page'] ?? 0,
      segments: parsedSegments,
      audioStartMs: json['audioStartMs'],
      audioEndMs: json['audioEndMs'],
    );
  }
}

class TimelineSegment {
  final String type; // 'recitation', 'chanting_interval', etc.
  final String? text;

  // Audio fields for future support
  final int? startMs;
  final int? endMs;

  TimelineSegment({required this.type, this.text, this.startMs, this.endMs});

  factory TimelineSegment.fromJson(Map<String, dynamic> json) {
    return TimelineSegment(
      type: json['type'] ?? 'recitation',
      text: json['text'],
      startMs: json['startMs'],
      endMs: json['endMs'],
    );
  }
}
