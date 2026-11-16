import 'package:intl/intl.dart';

import '../money/money.dart';

/// Formats [Money] for display, e.g. `₱1,234.50` or `-₱3,000.00`.
///
/// The currency symbol, digit grouping and decimal places come from `intl`.
/// Formatting uses integer arithmetic only, so large amounts are exact.
///
/// Limitation: negative amounts always use a leading minus sign, and the
/// locale is assumed to use ASCII digits. Both hold for English locales.
abstract final class MoneyFormatter {
  /// [locale] defaults to the app's current `intl` locale.
  static String format(Money money, {String? locale}) {
    final decimalDigits = Money.decimalDigitsFor(money.currencyCode);
    final wholeFormat = NumberFormat.simpleCurrency(
      locale: locale,
      name: money.currencyCode,
      decimalDigits: 0,
    );

    // Split before taking absolute values so the most negative int is safe.
    final perWhole = Money.minorUnitsPerWhole(money.currencyCode);
    final whole = wholeFormat.format((money.minorUnits ~/ perWhole).abs());

    var result = whole;
    if (decimalDigits > 0) {
      final fraction = money.minorUnits
          .remainder(perWhole)
          .abs()
          .toString()
          .padLeft(decimalDigits, '0');
      final insertAt = whole.lastIndexOf(RegExp(r'\d')) + 1;
      result =
          '${whole.substring(0, insertAt)}'
          '${wholeFormat.symbols.DECIMAL_SEP}$fraction'
          '${whole.substring(insertAt)}';
    }

    return money.isNegative
        ? '${wholeFormat.symbols.MINUS_SIGN}$result'
        : result;
  }

  /// Formats [money] for pre-filling a text field: no symbol or grouping,
  /// e.g. `3000.00`. The result parses back with `MoneyParser`.
  ///
  /// Uses the absolute value, because amounts are entered as positive values.
  static String formatForInput(Money money) {
    final decimalDigits = Money.decimalDigitsFor(money.currencyCode);
    final perWhole = Money.minorUnitsPerWhole(money.currencyCode);
    final whole = (money.minorUnits ~/ perWhole).abs();
    if (decimalDigits == 0) return '$whole';
    final fraction = money.minorUnits
        .remainder(perWhole)
        .abs()
        .toString()
        .padLeft(decimalDigits, '0');
    return '$whole.$fraction';
  }

  /// The currency symbol for [currencyCode], e.g. `₱` for PHP.
  static String symbolFor(String currencyCode, {String? locale}) =>
      NumberFormat.simpleCurrency(
        locale: locale,
        name: currencyCode,
      ).currencySymbol;
}
