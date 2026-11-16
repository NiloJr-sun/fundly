import 'package:flutter/foundation.dart';

import 'calendar_date.dart';

/// An inclusive range of calendar dates.
@immutable
final class DateRange {
  /// Throws [ArgumentError] if [end] is before [start].
  DateRange(this.start, this.end) {
    if (end.isBefore(start)) {
      throw ArgumentError('$end is before $start.');
    }
  }

  /// The whole calendar month containing [date].
  factory DateRange.monthOf(CalendarDate date) => DateRange(
    CalendarDate(date.year, date.month, 1),
    // Day 0 of the next month is the last day of this one.
    CalendarDate.fromDateTime(DateTime.utc(date.year, date.month + 1, 0)),
  );

  /// The whole calendar month before the one containing [date].
  factory DateRange.monthBefore(CalendarDate date) => DateRange.monthOf(
    // Day 1 of month 0 normalises to December of the previous year.
    CalendarDate.fromDateTime(DateTime.utc(date.year, date.month - 1, 1)),
  );

  final CalendarDate start;
  final CalendarDate end;

  bool contains(CalendarDate date) =>
      !date.isBefore(start) && !date.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start – $end)';
}
