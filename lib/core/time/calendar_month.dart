import 'package:flutter/foundation.dart';

import 'calendar_date.dart';
import 'date_range.dart';

/// A calendar month with no timezone, such as November 2026.
///
/// Monthly plans belong to a month. Stored as `YYYY-MM`, which sorts
/// correctly as text.
@immutable
final class CalendarMonth implements Comparable<CalendarMonth> {
  /// Throws [ArgumentError] unless [month] is 1-12 and [year] is 0-9999.
  CalendarMonth(this.year, this.month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be 1-12.');
    }
    if (year < 0 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'Must be 0-9999.');
    }
  }

  /// The month containing [date].
  factory CalendarMonth.of(CalendarDate date) =>
      CalendarMonth(date.year, date.month);

  /// Parses `YYYY-MM`. Throws [FormatException] otherwise.
  factory CalendarMonth.parse(String text) {
    final match = _isoPattern.firstMatch(text);
    if (match == null) throw FormatException('Expected YYYY-MM.', text);
    try {
      return CalendarMonth(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
    } on ArgumentError {
      throw FormatException('Not a valid month.', text);
    }
  }

  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})$');

  final int year;
  final int month;

  /// `YYYY-MM`.
  String toIsoString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  /// Every day of this month, first to last.
  DateRange get dateRange => DateRange.monthOf(CalendarDate(year, month, 1));

  CalendarMonth get previous =>
      month == 1 ? CalendarMonth(year - 1, 12) : CalendarMonth(year, month - 1);

  CalendarMonth get next =>
      month == 12 ? CalendarMonth(year + 1, 1) : CalendarMonth(year, month + 1);

  @override
  int compareTo(CalendarMonth other) => year != other.year
      ? year.compareTo(other.year)
      : month.compareTo(other.month);

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => toIsoString();
}
