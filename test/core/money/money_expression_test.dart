import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/money/money_expression.dart';
import 'package:fundly/core/money/money_parser.dart';

void main() {
  Money php(int minorUnits) =>
      Money(minorUnits: minorUnits, currencyCode: 'PHP');

  Money evaluate(String text) =>
      evaluateMoneyExpression(text, currencyCode: 'PHP');

  Matcher throwsParse(MoneyParseError error) => throwsA(
    isA<MoneyParseException>().having((e) => e.error, 'error', error),
  );

  test('a single amount is itself', () {
    expect(evaluate('10000'), php(1000000));
    expect(evaluate('10000.50'), php(1000050));
    expect(evaluate('.5'), php(50));
  });

  test('adds and subtracts in whole centavos', () {
    expect(evaluate('10000+2500'), php(1250000));
    expect(evaluate('0.10+0.20'), php(30));
    expect(evaluate('100-0.01'), php(9999));
    expect(evaluate('1+2+3-4'), php(200));
  });

  test('a result below zero is returned for the caller to judge', () {
    expect(evaluate('100-200'), php(-10000));
  });

  test('a missing amount is invalid', () {
    for (final text in ['5+', '+5', '5+-3', '-5', '5--3']) {
      expect(
        () => evaluate(text),
        throwsParse(MoneyParseError.invalid),
        reason: text,
      );
    }
  });

  test('each amount follows the parser rules', () {
    expect(() => evaluate(''), throwsParse(MoneyParseError.empty));
    expect(
      () => evaluate('1.234'),
      throwsParse(MoneyParseError.tooManyDecimals),
    );
    expect(() => evaluate('1.2.3'), throwsParse(MoneyParseError.invalid));
  });

  test('a sum past the largest amount is too large', () {
    expect(
      () => evaluate('999999999999.99+0.01'),
      throwsParse(MoneyParseError.tooLarge),
    );
    expect(evaluate('999999999999.98+0.01'), php(99999999999999));
  });
}
