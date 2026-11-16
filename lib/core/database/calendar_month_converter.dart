import 'package:drift/drift.dart';

import '../time/calendar_month.dart';

/// Stores a [CalendarMonth] as `YYYY-MM` text, which sorts by month.
class CalendarMonthConverter extends TypeConverter<CalendarMonth, String> {
  const CalendarMonthConverter();

  @override
  CalendarMonth fromSql(String fromDb) => CalendarMonth.parse(fromDb);

  @override
  String toSql(CalendarMonth value) => value.toIsoString();
}
