import 'package:html_unescape/html_unescape.dart';

class HtmlCleaner {
  static final _unescape = HtmlUnescape();

  /// Cleans basic WordPress HTML for simple text display.
  /// Converts <p> and <br> to newlines and unescapes HTML entities.
  static String clean(String htmlString) {
    if (htmlString.isEmpty) return '';

    // 1. Replace <br> and <p> with newlines
    String text = htmlString
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');

    // 2. Strip all remaining HTML tags safely
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 3. Decode HTML entities (e.g., &#8221; -> ")
    text = _unescape.convert(text);

    // 4. Trim extra whitespace and excessive newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    return text;
  }
}
