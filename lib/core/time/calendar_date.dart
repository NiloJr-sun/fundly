import 'package:flutter/foundation.dart';

/// A calendar day with no time of day or timezone (CLAUDE.md §11, G9).
///
/// Transactions happen on a date, not at an instant, so the same entry shows
/// the same day wherever the phone's timezone is set. Stored as `YYYY-MM-DD`,
/// which sorts correctly as text.
@immutable
final class CalendarDate implements Comparable<CalendarDate> {
  /// Throws [ArgumentError] for a day that does not exist, e.g. Feb 30.
  CalendarDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('$year-$month-$day is not a valid date.');
    }
  }

  /// The calendar date of [dateTime] as it reads in its own timezone.
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  /// Today in the device's local timezone.
  factory CalendarDate.today({DateTime Function()? clock}) =>
      CalendarDate.fromDateTime((clock ?? DateTime.now)().toLocal());

  /// Parses `YYYY-MM-DD`. Throws [FormatException] otherwise.
  factory CalendarDate.parse(String text) {
    final match = _isoPattern.firstMatch(text);
    if (match == null) {
      throw FormatException('Expected YYYY-MM-DD.', text);
    }
    try {
      return CalendarDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('Not a valid date.', text);
    }
  }

  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// `YYYY-MM-DD`.
  String toIsoString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Midnight at the start of this date in the local timezone, for display
  /// with date formatters.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIsoString();
}
