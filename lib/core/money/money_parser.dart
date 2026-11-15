import 'money.dart';

/// Why user-entered text could not be turned into [Money].
enum MoneyParseError {
  /// Nothing was entered.
  empty,

  /// The text is not a number in the accepted format.
  invalid,

  /// A minus sign was entered. Amounts are always entered as positive values;
  /// the account or transaction type decides the sign.
  negative,

  /// More decimal places than the currency allows (e.g. `10.555` for PHP).
  /// Rejected rather than rounded so a typo never silently changes an amount.
  tooManyDecimals,

  /// Larger than [MoneyParser.maxWholeDigits] digits before the decimal point.
  tooLarge,
}

class MoneyParseException implements Exception {
  const MoneyParseException(this.error, this.input);

  final MoneyParseError error;
  final String input;

  @override
  String toString() => 'MoneyParseException(${error.name}, "$input")';
}

/// Parses amounts typed by the user, such as `1,234.50`, `1234.5` or `.50`.
///
/// Accepts digits, optional comma thousands separators in groups of three and
/// one `.` decimal point. Surrounding whitespace is ignored. Zero is accepted
/// (for example, an opening balance); rules that require a positive amount
/// belong to the caller.
abstract final class MoneyParser {
  /// Upper bound on whole units (just under one trillion), far beyond
  /// personal-finance values and well inside 64-bit integer range.
  static const int maxWholeDigits = 12;

  static final RegExp _plainDigits = RegExp(r'^\d+$');
  static final RegExp _groupedDigits = RegExp(r'^\d{1,3}(,\d{3})+$');

  /// Throws [MoneyParseException] when [input] is not a valid amount.
  static Money parse(String input, {required String currencyCode}) {
    final text = input.trim();
    if (text.isEmpty) {
      throw MoneyParseException(MoneyParseError.empty, input);
    }
    if (text.startsWith('-')) {
      throw MoneyParseException(MoneyParseError.negative, input);
    }

    final parts = text.split('.');
    if (parts.length > 2) {
      throw MoneyParseException(MoneyParseError.invalid, input);
    }
    final wholePart = parts[0];
    final fractionPart = parts.length == 2 ? parts[1] : '';

    final hasDigits = wholePart.isNotEmpty || fractionPart.isNotEmpty;
    final wholeIsValid =
        wholePart.isEmpty ||
        _plainDigits.hasMatch(wholePart) ||
        _groupedDigits.hasMatch(wholePart);
    final fractionIsValid =
        fractionPart.isEmpty || _plainDigits.hasMatch(fractionPart);
    if (!hasDigits || !wholeIsValid || !fractionIsValid) {
      throw MoneyParseException(MoneyParseError.invalid, input);
    }

    final decimalDigits = Money.decimalDigitsFor(currencyCode);
    if (fractionPart.length > decimalDigits) {
      throw MoneyParseException(MoneyParseError.tooManyDecimals, input);
    }

    final wholeDigits = wholePart
        .replaceAll(',', '')
        .replaceFirst(RegExp(r'^0+'), '');
    if (wholeDigits.length > maxWholeDigits) {
      throw MoneyParseException(MoneyParseError.tooLarge, input);
    }

    final whole = wholeDigits.isEmpty ? 0 : int.parse(wholeDigits);
    final fraction = fractionPart.isEmpty
        ? 0
        : int.parse(fractionPart.padRight(decimalDigits, '0'));

    return Money(
      minorUnits: whole * Money.minorUnitsPerWhole(currencyCode) + fraction,
      currencyCode: currencyCode,
    );
  }
}
