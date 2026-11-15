import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  group('Money', () {
    test('equality compares amount and currency', () {
      expect(php(100), php(100));
      expect(php(100).hashCode, php(100).hashCode);
      expect(php(100), isNot(php(101)));
      expect(
        php(100),
        isNot(const Money(minorUnits: 100, currencyCode: 'USD')),
      );
    });

    test('zero', () {
      expect(const Money.zero('PHP'), php(0));
      expect(const Money.zero('PHP').isZero, isTrue);
    });

    test('adds and subtracts exactly', () {
      expect(php(10) + php(20), php(30));
      expect(php(10) - php(30), php(-20));
      expect((php(10) - php(30)).isNegative, isTrue);
    });

    test('negation', () {
      expect(-php(300000), php(-300000));
      expect(-(-php(5)), php(5));
    });

    test('0.10 + 0.20 is exactly 0.30 (no floating-point error)', () {
      expect(php(10) + php(20), php(30));
    });

    test('rejects combining different currencies', () {
      const usd = Money(minorUnits: 100, currencyCode: 'USD');
      expect(() => php(100) + usd, throwsArgumentError);
      expect(() => php(100) - usd, throwsArgumentError);
    });

    test('decimal digits come from the currency', () {
      expect(Money.decimalDigitsFor('PHP'), 2);
      expect(Money.decimalDigitsFor('JPY'), 0);
    });
  });
}
