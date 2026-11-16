import 'package:drift/drift.dart';

import '../time/calendar_date.dart';

/// Stores a [CalendarDate] as `YYYY-MM-DD` text, which sorts by date.
class CalendarDateConverter extends TypeConverter<CalendarDate, String> {
  const CalendarDateConverter();

  @override
  CalendarDate fromSql(String fromDb) => CalendarDate.parse(fromDb);

  @override
  String toSql(CalendarDate value) => value.toIsoString();
}
