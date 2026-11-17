import 'package:intl/intl.dart';

import '../time/date_range.dart';

/// Formats dates for display in the user's local timezone (CLAUDE.md rule 10).
abstract final class DateFormatter {
  /// A medium date such as `Nov 16, 2026`, converted to local time first.
  static String localDate(DateTime instant, {String? locale}) =>
      DateFormat.yMMMd(locale).format(instant.toLocal());

  /// A month and year such as `November 2026`.
  static String monthYear(int year, int month, {String? locale}) =>
      DateFormat.yMMMM(locale).format(DateTime(year, month));

  /// An inclusive range such as `Oct 1, 2026 – Oct 15, 2026`.
  static String dateRange(DateRange range, {String? locale}) =>
      '${DateFormat.yMMMd(locale).format(range.start.toLocalDateTime())} – '
      '${DateFormat.yMMMd(locale).format(range.end.toLocalDateTime())}';
}
