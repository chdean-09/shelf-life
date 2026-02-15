/// Utility class for parsing expiry dates from OCR text recognition.
class ExpiryDateParser {
  static final List<RegExp> _patterns = [
    // MM/DD/YYYY or MM-DD-YYYY or MM.DD.YYYY
    RegExp(r'(\d{2})[/\-\.](\d{2})[/\-\.](\d{4})'),
    // YYYY/MM/DD or YYYY-MM-DD or YYYY.MM.DD
    RegExp(r'(\d{4})[/\-\.](\d{2})[/\-\.](\d{2})'),
    // MM/DD/YY or MM-DD-YY
    RegExp(r'(\d{2})[/\-\.](\d{2})[/\-\.](\d{2})'),
    // DD MON YYYY (e.g., 12 DEC 2025)
    RegExp(
      r'(\d{1,2})\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{2,4})',
      caseSensitive: false,
    ),
    // MON DD, YYYY (e.g., DEC 12, 2025)
    RegExp(
      r'(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{1,2}),?\s*(\d{2,4})',
      caseSensitive: false,
    ),
    // BB MM/YY or EXP MM/YY
    RegExp(r'(?:BB|EXP|USE BY|BEST BEFORE)\s*(\d{2})[/\-](\d{2,4})',
        caseSensitive: false),
  ];

  static const Map<String, int> _monthNames = {
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };

  /// Attempts to parse an expiry date from OCR-recognized text.
  /// Returns null if no date pattern is found.
  static DateTime? parse(String text) {
    // Normalize the text
    final normalizedText = text.toUpperCase().trim();

    // Try each pattern
    for (int i = 0; i < _patterns.length; i++) {
      final match = _patterns[i].firstMatch(normalizedText);
      if (match != null) {
        try {
          return _parseMatch(match, i);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  /// Parses all possible dates from a block of text.
  static List<DateTime> parseAll(String text) {
    final dates = <DateTime>[];
    final normalizedText = text.toUpperCase().trim();

    for (int i = 0; i < _patterns.length; i++) {
      final matches = _patterns[i].allMatches(normalizedText);
      for (var match in matches) {
        try {
          final date = _parseMatch(match, i);
          if (date != null) {
            dates.add(date);
          }
        } catch (_) {
          continue;
        }
      }
    }
    return dates;
  }

  static DateTime? _parseMatch(RegExpMatch match, int patternIndex) {
    int year, month, day;

    switch (patternIndex) {
      case 0: // MM/DD/YYYY
        month = int.parse(match.group(1)!);
        day = int.parse(match.group(2)!);
        year = int.parse(match.group(3)!);
        break;
      case 1: // YYYY/MM/DD
        year = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        day = int.parse(match.group(3)!);
        break;
      case 2: // MM/DD/YY
        month = int.parse(match.group(1)!);
        day = int.parse(match.group(2)!);
        year = _expandYear(int.parse(match.group(3)!));
        break;
      case 3: // DD MON YYYY
        day = int.parse(match.group(1)!);
        month = _monthNames[match.group(2)!.toUpperCase()]!;
        year = _expandYear(int.parse(match.group(3)!));
        break;
      case 4: // MON DD, YYYY
        month = _monthNames[match.group(1)!.toUpperCase()]!;
        day = int.parse(match.group(2)!);
        year = _expandYear(int.parse(match.group(3)!));
        break;
      case 5: // BB MM/YY or EXP MM/YY
        month = int.parse(match.group(1)!);
        year = _expandYear(int.parse(match.group(2)!));
        day = _lastDayOfMonth(year, month); // Assume end of month
        break;
      default:
        return null;
    }

    // Validate the parsed date
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static int _expandYear(int year) {
    if (year < 100) {
      return year + 2000;
    }
    return year;
  }

  static int _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
