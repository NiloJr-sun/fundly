import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/formatting/money_formatter.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/money/money_parser.dart';

String formatPhp(int minorUnits) => MoneyFormatter.format(
  Money(minorUnits: minorUnits, currencyCode: 'PHP'),
  locale: 'en',
);

void main() {
  group('MoneyFormatter', () {
    final cases = <int, String>{
      0: '₱0.00',
      5: '₱0.05',
      50: '₱0.50',
      123450: '₱1,234.50',
      100000000: '₱1,000,000.00',
      -300000: '-₱3,000.00',
      -50: '-₱0.50',
    };
    cases.forEach((minorUnits, expected) {
      test('$minorUnits -> $expected', () {
        expect(formatPhp(minorUnits), expected);
      });
    });

    test('formats very large amounts exactly (no floating point)', () {
      expect(formatPhp(9007199254740993), '₱90,071,992,547,409.93');
      expect(formatPhp(-9223372036854775807), '-₱92,233,720,368,547,758.07');
    });

    test('uses the currency decimal places (JPY has none)', () {
      expect(
        MoneyFormatter.format(
          const Money(minorUnits: 1234, currencyCode: 'JPY'),
          locale: 'en',
        ),
        '¥1,234',
      );
    });
  });

  group('MoneyFormatter.formatForInput', () {
    final cases = <int, String>{
      0: '0.00',
      5: '0.05',
      123450: '1234.50',
      -300000: '3000.00',
      -50: '0.50',
    };
    cases.forEach((minorUnits, expected) {
      test('$minorUnits -> $expected', () {
        expect(
          MoneyFormatter.formatForInput(
            Money(minorUnits: minorUnits, currencyCode: 'PHP'),
          ),
          expected,
        );
      });
    });

    test('round-trips through MoneyParser', () {
      for (final minorUnits in [0, 1, 99, 100, 123456789, 99999999999999]) {
        final money = Money(minorUnits: minorUnits, currencyCode: 'PHP');
        expect(
          MoneyParser.parse(
            MoneyFormatter.formatForInput(money),
            currencyCode: 'PHP',
          ),
          money,
        );
      }
    });

    test('has no decimal point for JPY', () {
      expect(
        MoneyFormatter.formatForInput(
          const Money(minorUnits: 1234, currencyCode: 'JPY'),
        ),
        '1234',
      );
    });
  });

  test('symbolFor', () {
    expect(MoneyFormatter.symbolFor('PHP', locale: 'en'), '₱');
  });
}
