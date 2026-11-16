import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/core/time/date_range.dart';

void main() {
  group('CalendarMonth', () {
    test('rejects months outside 1-12', () {
      expect(() => CalendarMonth(2026, 0), throwsArgumentError);
      expect(() => CalendarMonth(2026, 13), throwsArgumentError);
    });

    test('of takes the month of a date', () {
      expect(
        CalendarMonth.of(CalendarDate(2026, 11, 16)),
        CalendarMonth(2026, 11),
      );
    });

    test('round-trips YYYY-MM with zero padding', () {
      final month = CalendarMonth(2026, 3);

      expect(month.toIsoString(), '2026-03');
      expect(CalendarMonth.parse('2026-03'), month);
    });

    test('parse rejects malformed and impossible months', () {
      for (final text in ['2026-3', '2026-13', '2026-00', '202611', '']) {
        expect(
          () => CalendarMonth.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('dateRange covers every day of the month', () {
      expect(
        CalendarMonth(2028, 2).dateRange,
        DateRange(CalendarDate(2028, 2, 1), CalendarDate(2028, 2, 29)),
      );
    });

    test('previous and next cross year boundaries', () {
      expect(CalendarMonth(2026, 1).previous, CalendarMonth(2025, 12));
      expect(CalendarMonth(2026, 12).next, CalendarMonth(2027, 1));
      expect(CalendarMonth(2026, 11).next, CalendarMonth(2026, 12));
    });

    test('orders by year then month', () {
      final months = [
        CalendarMonth(2027, 1),
        CalendarMonth(2026, 12),
        CalendarMonth(2026, 2),
      ]..sort();

      expect(months, [
        CalendarMonth(2026, 2),
        CalendarMonth(2026, 12),
        CalendarMonth(2027, 1),
      ]);
    });
  });
}
