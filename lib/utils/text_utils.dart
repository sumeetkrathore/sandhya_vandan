/// Typographic and text utility functions for the Sandhya Vandan app.
class TextUtils {
  /// Balances lines for centered titles/headings so that if the text needs to wrap
  /// onto multiple lines, it splits near natural word boundaries with balanced character lengths,
  /// keeping the font size large, prominent, and uniform without dropping 1 or 2 orphan words at the end.
  static String balanceCenteredLines(
    String text, {
    int singleLineThreshold = 20,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length <= singleLineThreshold) {
      return trimmed;
    }

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 2) {
      return preventOrphans(trimmed);
    }

    // Determine target number of lines (2 lines for <= 45 chars, 3 lines for > 45 chars)
    final numLines = (trimmed.length > 45 && words.length >= 6) ? 3 : 2;

    if (numLines == 2) {
      final mid = trimmed.length / 2;
      int bestSpaceIndex = -1;
      double bestDistance = double.infinity;

      int currentPos = 0;
      for (int i = 0; i < words.length - 1; i++) {
        currentPos += words[i].length;
        final distance = (currentPos - mid).abs();
        final wordsInFirst = i + 1;
        final wordsInSecond = words.length - wordsInFirst;

        // Ensure at least 2 words on each line if there are 4+ words
        if (words.length >= 4 && (wordsInFirst < 2 || wordsInSecond < 2)) {
          currentPos += 1; // skip space
          continue;
        }

        if (distance < bestDistance) {
          bestDistance = distance;
          bestSpaceIndex = currentPos;
        }
        currentPos += 1; // for space
      }

      if (bestSpaceIndex != -1) {
        final line1 = trimmed.substring(0, bestSpaceIndex).trim();
        final line2 = trimmed.substring(bestSpaceIndex + 1).trim();
        return '$line1\n$line2';
      }
    } else {
      // 3 balanced lines for very long titles (> 45 chars)
      final target = trimmed.length / 3;
      int split1 = -1;
      int split2 = -1;
      double bestDist1 = double.infinity;
      double bestDist2 = double.infinity;

      int currentPos = 0;
      for (int i = 0; i < words.length - 1; i++) {
        currentPos += words[i].length;
        final dist1 = (currentPos - target).abs();
        final dist2 = (currentPos - target * 2).abs();

        if (dist1 < bestDist1 && (i + 1) >= 2) {
          bestDist1 = dist1;
          split1 = currentPos;
        }
        if (dist2 < bestDist2 &&
            (words.length - (i + 1)) >= 2 &&
            currentPos > (split1 > 0 ? split1 : 0)) {
          bestDist2 = dist2;
          split2 = currentPos;
        }
        currentPos += 1;
      }

      if (split1 != -1 && split2 != -1 && split2 > split1) {
        final line1 = trimmed.substring(0, split1).trim();
        final line2 = trimmed.substring(split1 + 1, split2).trim();
        final line3 = trimmed.substring(split2 + 1).trim();
        return '$line1\n$line2\n$line3';
      }
    }

    return preventOrphans(trimmed);
  }

  /// Prevents typographic "widows" and "orphans" (1 or 2 isolated words on the last line).
  ///
  /// Replaces the space before the trailing word(s) with a non-breaking space (`\u00A0`),
  /// ensuring the last 2-3 words (especially honorifics like "Ji", "Sahib", "Maharaj")
  /// always stick together when wrapping across lines.
  static String preventOrphans(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 1) return trimmed;

    // If text ends with or has short particles like "Ji", "Maharaj Ji", "Sahib Ji":
    // bind the last 3 words if >= 3 words.
    final lastWord = words.last;
    final secondLastWord = words.length >= 2 ? words[words.length - 2] : '';

    if (words.length >= 3 &&
        (lastWord.length <= 3 || secondLastWord.length <= 3)) {
      final prefix = words.sublist(0, words.length - 2).join(' ');
      return '$prefix ${words[words.length - 2]}\u00A0$lastWord';
    }

    // For general titles: bind the last 2 words with non-breaking space
    final prefix = words.sublist(0, words.length - 1).join(' ');
    return '$prefix\u00A0$lastWord';
  }

  /// Extracts a clean Satguru name from raw WordPress title by stripping
  /// repetitive prefixes ("First Patshahi", etc.) and date suffixes.
  static String cleanSatguruName(String rawTitle) {
    var title = rawTitle.trim();
    // Strip duplicate patshahi prefixes
    title = title
        .replaceFirst(
          RegExp(
            r'^(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|\d+st|\d+nd|\d+rd|\d+th)\s+(?:patshahi|light|gaddi nasheen|gadi nasheen)\s*(?:[:\-]|&#8211;|&#8212;)*\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Strip date ranges in parentheses e.g. (1850 - 1920) or (Present)
    title = title.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    return title.replaceAll(RegExp(r'^[,\-:\s]+|[,\-:\s]+$'), '').trim();
  }

  /// Converts all standard ASCII digits (0-9) in a string to Devanagari digits (०-९).
  static String toDevanagariDigits(String text) {
    if (text.isEmpty) return text;
    const arabic = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

    String result = text;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabic[i], devanagari[i]);
    }
    return result;
  }
}
