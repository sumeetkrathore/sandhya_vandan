enum ProgramStatus { ongoing, upcoming, past }

class ProgramPoster {
  final String url;
  final String region;

  ProgramPoster({required this.url, required this.region});
}

class Program {
  final int id;
  final String title;
  final String startDate;
  final String endDate;
  final String programTime;
  final String location;
  final String address;
  final String description;
  final List<ProgramPoster> posters;
  final String link;

  Program({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.programTime = '',
    required this.location,
    required this.address,
    required this.description,
    required this.posters,
    required this.link,
  });

  String get url => link;

  ProgramStatus get status {
    final now = DateTime.now();
    try {
      final start = startDate.isNotEmpty ? DateTime.tryParse(startDate) : null;
      final end = endDate.isNotEmpty ? DateTime.tryParse(endDate) : null;

      if (start == null && end == null) return ProgramStatus.upcoming;

      if (start != null && end == null) {
        final dayStart = DateTime(start.year, start.month, start.day);
        final dayEnd = DateTime(start.year, start.month, start.day, 23, 59, 59);
        if (now.isAfter(dayStart) && now.isBefore(dayEnd)) {
          return ProgramStatus.ongoing;
        } else if (now.isBefore(dayStart)) {
          return ProgramStatus.upcoming;
        } else {
          return ProgramStatus.past;
        }
      }

      if (start != null && end != null) {
        // Business rule: Event ends on the next date at 12:00 PM noon
        final cutoff = DateTime(
          end.year,
          end.month,
          end.day,
        ).add(const Duration(days: 1, hours: 12));

        if (now.isAfter(start) && now.isBefore(cutoff)) {
          return ProgramStatus.ongoing;
        } else if (now.isBefore(start)) {
          return ProgramStatus.upcoming;
        } else {
          return ProgramStatus.past;
        }
      }
    } catch (_) {}

    return ProgramStatus.upcoming;
  }

  bool get isOngoing => status == ProgramStatus.ongoing;
  bool get isUpcoming => status == ProgramStatus.upcoming;
  bool get isPast => status == ProgramStatus.past;

  String get statusBadgeLabel {
    switch (status) {
      case ProgramStatus.ongoing:
        return 'HAPPENING NOW';
      case ProgramStatus.upcoming:
        return 'UPCOMING';
      case ProgramStatus.past:
        return 'COMPLETED';
    }
  }

  factory Program.fromJson(Map<String, dynamic> json) {
    final title = json['title'] != null ? json['title']['rendered'] ?? '' : '';
    final meta = json['meta'] ?? {};

    // Parse posters with region
    List<ProgramPoster> posterList = [];
    final postersData = meta['program_posters'];

    if (postersData is Map) {
      postersData.forEach((key, value) {
        if (value is Map && value['poster'] != null) {
          posterList.add(
            ProgramPoster(
              url: value['poster'] as String,
              region: value['region'] as String? ?? '',
            ),
          );
        }
      });
    } else if (postersData is List) {
      for (final value in postersData) {
        if (value is Map && value['poster'] != null) {
          posterList.add(
            ProgramPoster(
              url: value['poster'] as String,
              region: value['region'] as String? ?? '',
            ),
          );
        }
      }
    }

    return Program(
      id: json['id'] ?? 0,
      title: _cleanTitle(title),
      startDate: meta['program_start'] ?? '',
      endDate: meta['program_end'] ?? '',
      programTime: meta['program_time'] ?? '',
      location: meta['location'] ?? '',
      address: meta['address'] ?? '',
      description: meta['_description'] ?? '',
      posters: posterList,
      link: json['link'] ?? '',
    );
  }

  static String _cleanTitle(String text) {
    String decoded = _decodeHtmlString(text);
    return decoded
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .replaceFirst(
          RegExp(
            r'^\s*(HAPPENING NOW|UPCOMING|LIVE|FUTURE)\s*:\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static String _decodeHtmlString(String text) {
    return text
        .replaceAll('&#038;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8211;', '-')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8217;', "'");
  }
}
