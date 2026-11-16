import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';

void main() {
  group('DateRange', () {
    test('rejects an end before the start', () {
      expect(
        () => DateRange(CalendarDate(2026, 11, 2), CalendarDate(2026, 11, 1)),
        throwsArgumentError,
      );
    });

    test('a single day is allowed', () {
      final day = CalendarDate(2026, 11, 16);

      expect(DateRange(day, day).contains(day), isTrue);
    });

    test('contains is inclusive at both ends', () {
      final range = DateRange(
        CalendarDate(2026, 11, 1),
        CalendarDate(2026, 11, 30),
      );

      expect(range.contains(CalendarDate(2026, 10, 31)), isFalse);
      expect(range.contains(CalendarDate(2026, 11, 1)), isTrue);
      expect(range.contains(CalendarDate(2026, 11, 30)), isTrue);
      expect(range.contains(CalendarDate(2026, 12, 1)), isFalse);
    });

    group('monthOf', () {
      final cases = {
        CalendarDate(2026, 11, 16): ('2026-11-01', '2026-11-30'),
        CalendarDate(2026, 12, 31): ('2026-12-01', '2026-12-31'),
        CalendarDate(2026, 2, 10): ('2026-02-01', '2026-02-28'),
        CalendarDate(2028, 2, 10): ('2028-02-01', '2028-02-29'),
        CalendarDate(2027, 1, 1): ('2027-01-01', '2027-01-31'),
      };
      cases.forEach((date, expected) {
        test('$date -> ${expected.$1} to ${expected.$2}', () {
          final range = DateRange.monthOf(date);

          expect(range.start.toIsoString(), expected.$1);
          expect(range.end.toIsoString(), expected.$2);
        });
      });
    });
  });
}
