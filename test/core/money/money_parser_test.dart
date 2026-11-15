import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/money/money_parser.dart';

int parsePhp(String input) =>
    MoneyParser.parse(input, currencyCode: 'PHP').minorUnits;

Matcher throwsParseError(MoneyParseError error) =>
    throwsA(isA<MoneyParseException>().having((e) => e.error, 'error', error));

void main() {
  group('MoneyParser accepts', () {
    final cases = <String, int>{
      '1,234.50': 123450,
      '1234.50': 123450,
      '1234.5': 123450,
      '1234': 123400,
      '1234.': 123400,
      '.50': 50,
      '0.05': 5,
      '  42.10  ': 4210,
      '1,234,567.89': 123456789,
      '007': 700,
      '0': 0,
      '0.00': 0,
      '999,999,999,999.99': 99999999999999,
    };
    cases.forEach((input, expected) {
      test('"$input" -> $expected', () {
        expect(parsePhp(input), expected);
      });
    });

    test('keeps the currency code', () {
      expect(
        MoneyParser.parse('1', currencyCode: 'PHP'),
        const Money(minorUnits: 100, currencyCode: 'PHP'),
      );
    });

    test('uses the currency decimal places (JPY has none)', () {
      expect(MoneyParser.parse('1,234', currencyCode: 'JPY').minorUnits, 1234);
    });
  });

  group('MoneyParser rejects', () {
    test('empty input', () {
      expect(() => parsePhp(''), throwsParseError(MoneyParseError.empty));
      expect(() => parsePhp('   '), throwsParseError(MoneyParseError.empty));
    });

    test('negative amounts', () {
      expect(() => parsePhp('-5'), throwsParseError(MoneyParseError.negative));
      expect(
        () => parsePhp(' -0.01'),
        throwsParseError(MoneyParseError.negative),
      );
    });

    test('more decimals than the currency allows', () {
      expect(
        () => parsePhp('10.555'),
        throwsParseError(MoneyParseError.tooManyDecimals),
      );
      expect(
        () => MoneyParser.parse('100.5', currencyCode: 'JPY'),
        throwsParseError(MoneyParseError.tooManyDecimals),
      );
    });

    test('amounts with more than 12 whole digits', () {
      expect(
        () => parsePhp('1,000,000,000,000'),
        throwsParseError(MoneyParseError.tooLarge),
      );
      expect(
        () => parsePhp('99999999999999999999999'),
        throwsParseError(MoneyParseError.tooLarge),
      );
    });

    for (final input in [
      'abc',
      '1.2.3',
      '.',
      '1,23',
      '12,34.5',
      ',123',
      '1 000',
      '+5',
      '1e5',
      '₱100',
      '10.5a',
      '1,234.5,0',
    ]) {
      test('invalid format "$input"', () {
        expect(
          () => parsePhp(input),
          throwsParseError(MoneyParseError.invalid),
        );
      });
    }
  });
}
