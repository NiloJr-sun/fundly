import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/formatting/date_formatter.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';

void main() {
  test('localDate formats a medium date in local time', () {
    // Noon UTC is the same calendar day in every timezone from -11 to +11.
    final instant = DateTime.utc(2026, 11, 16, 12);

    expect(DateFormatter.localDate(instant), 'Nov 16, 2026');
  });

  test('dateRange shows both inclusive ends', () {
    final range = DateRange(
      CalendarDate(2026, 10, 1),
      CalendarDate(2026, 10, 15),
    );

    expect(DateFormatter.dateRange(range), 'Oct 1, 2026 – Oct 15, 2026');
  });
}
