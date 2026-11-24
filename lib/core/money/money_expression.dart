import 'money.dart';
import 'money_parser.dart';

/// Evaluates a keypad sum such as `10000+2500.50-300` in whole minor units,
/// never floating point. Each amount follows [MoneyParser]; `+` and `-` join
/// them. The result may be negative; callers decide whether that is allowed.
///
/// Throws [MoneyParseException]: `invalid` for a missing amount (`5+`, `+5`,
/// `5+-3`), the parser's error for a bad amount, and `tooLarge` when the
/// result passes [MoneyParser.maxWholeDigits].
Money evaluateMoneyExpression(
  String expression, {
  required String currencyCode,
}) {
  final text = expression.replaceAll(' ', '');
  if (text.isEmpty) {
    throw MoneyParseException(MoneyParseError.empty, expression);
  }
  var total = Money.zero(currencyCode);
  var sign = 1;
  var start = 0;
  for (var i = 0; i <= text.length; i++) {
    final atEnd = i == text.length;
    if (!atEnd && text[i] != '+' && text[i] != '-') continue;
    final operand = text.substring(start, i);
    if (operand.isEmpty) {
      throw MoneyParseException(MoneyParseError.invalid, expression);
    }
    final amount = MoneyParser.parse(operand, currencyCode: currencyCode);
    total = sign > 0 ? total + amount : total - amount;
    if (!atEnd) {
      sign = text[i] == '+' ? 1 : -1;
      start = i + 1;
    }
  }
  final limit =
      Money.minorUnitsPerWhole(currencyCode) *
      _pow10(MoneyParser.maxWholeDigits);
  if (total.minorUnits.abs() >= limit) {
    throw MoneyParseException(MoneyParseError.tooLarge, expression);
  }
  return total;
}

int _pow10(int exponent) {
  var value = 1;
  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}
