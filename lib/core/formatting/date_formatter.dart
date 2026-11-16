import 'package:intl/intl.dart';

/// Formats dates for display in the user's local timezone (CLAUDE.md rule 10).
abstract final class DateFormatter {
  /// A medium date such as `Nov 16, 2026`, converted to local time first.
  static String localDate(DateTime instant, {String? locale}) =>
      DateFormat.yMMMd(locale).format(instant.toLocal());
}
