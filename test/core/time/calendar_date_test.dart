import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';

void main() {
  group('CalendarDate', () {
    test('rejects days that do not exist', () {
      expect(() => CalendarDate(2026, 2, 29), throwsArgumentError);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
      expect(() => CalendarDate(2026, 4, 31), throwsArgumentError);
      expect(CalendarDate(2028, 2, 29).day, 29, reason: 'leap year');
    });

    test('formats and parses YYYY-MM-DD', () {
      final date = CalendarDate(2026, 1, 5);

      expect(date.toIsoString(), '2026-01-05');
      expect(CalendarDate.parse('2026-01-05'), date);
    });

    test('parse rejects other formats and impossible dates', () {
      for (final text in ['2026-1-5', '05/01/2026', '2026-02-30', '']) {
        expect(
          () => CalendarDate.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('compares chronologically', () {
      final dates = [
        CalendarDate(2026, 11, 16),
        CalendarDate(2025, 12, 31),
        CalendarDate(2026, 2, 1),
      ]..sort();

      expect(dates.map((d) => d.toIsoString()), [
        '2025-12-31',
        '2026-02-01',
        '2026-11-16',
      ]);
      expect(dates.first.isBefore(dates.last), isTrue);
      expect(dates.last.isAfter(dates.first), isTrue);
    });

    test('ISO strings sort the same way as dates', () {
      final a = CalendarDate(2026, 2, 1);
      final b = CalendarDate(2026, 11, 16);

      expect(a.toIsoString().compareTo(b.toIsoString()), a.compareTo(b));
    });

    test('equality and hash', () {
      expect(CalendarDate(2026, 11, 16), CalendarDate(2026, 11, 16));
      expect(
        CalendarDate(2026, 11, 16).hashCode,
        CalendarDate(2026, 11, 16).hashCode,
      );
    });

    test('fromDateTime takes the date as it reads in its own timezone', () {
      // 23:30 UTC is already the next day in Manila (UTC+8), but a UTC
      // DateTime reads as the UTC date.
      expect(
        CalendarDate.fromDateTime(DateTime.utc(2026, 11, 16, 23, 30)),
        CalendarDate(2026, 11, 16),
      );
      expect(
        CalendarDate.fromDateTime(DateTime(2026, 11, 17, 7, 30)),
        CalendarDate(2026, 11, 17),
      );
    });

    test('today uses the local date of the clock', () {
      final now = DateTime(2026, 11, 16, 23, 59);

      expect(CalendarDate.today(clock: () => now), CalendarDate(2026, 11, 16));
    });
  });
}
