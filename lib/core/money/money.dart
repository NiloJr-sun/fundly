import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// An exact amount of money in a single currency.
///
/// Stored as an integer count of minor units (centavos for PHP) so that
/// arithmetic never suffers floating-point rounding (CLAUDE.md rule 9).
/// The sign is meaningful: see the balance convention in CLAUDE.md §11 (D1).
@immutable
final class Money {
  const Money({required this.minorUnits, required this.currencyCode});

  const Money.zero(this.currencyCode) : minorUnits = 0;

  /// Amount in minor units, e.g. `123450` for PHP 1,234.50.
  final int minorUnits;

  /// ISO 4217 currency code, e.g. `PHP`.
  final String currencyCode;

  /// Number of minor-unit digits for [currencyCode] (2 for PHP, 0 for JPY).
  static int decimalDigitsFor(String currencyCode) =>
      NumberFormat.simpleCurrency(name: currencyCode).decimalDigits ?? 2;

  /// Minor units in one whole unit of [currencyCode] (100 for PHP, 1 for JPY).
  static int minorUnitsPerWhole(String currencyCode) {
    var result = 1;
    for (var i = 0; i < decimalDigitsFor(currencyCode); i++) {
      result *= 10;
    }
    return result;
  }

  bool get isZero => minorUnits == 0;

  bool get isNegative => minorUnits < 0;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(
      minorUnits: minorUnits - other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  Money operator -() =>
      Money(minorUnits: -minorUnits, currencyCode: currencyCode);

  void _requireSameCurrency(Money other) {
    if (other.currencyCode != currencyCode) {
      throw ArgumentError(
        'Cannot combine $currencyCode with ${other.currencyCode}.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => 'Money($minorUnits $currencyCode)';
}
