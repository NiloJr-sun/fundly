import 'package:flutter/foundation.dart';

import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_expression.dart';
import '../../../core/money/money_parser.dart';

/// A key on the Assigned keypad.
enum AssignKey {
  digit0,
  digit1,
  digit2,
  digit3,
  digit4,
  digit5,
  digit6,
  digit7,
  digit8,
  digit9,
  decimalPoint,
  plus,
  minus,
  equals,
  backspace;

  /// The character the key types; `null` for [equals] and [backspace].
  String? get character => switch (this) {
    decimalPoint => '.',
    plus => '+',
    minus => '-',
    equals || backspace => null,
    _ => '$index',
  };

  bool get isOperator => this == plus || this == minus;
}

/// What is typed on the Assigned keypad: an amount or a sum like
/// `10000+2500`, kept as text until it is evaluated.
///
/// It starts with the current Assigned amount "selected": typing an amount
/// replaces it, while an operator continues from it, as on a calculator.
@immutable
final class AssignDraft {
  const AssignDraft._(this.text, {required this.replaceOnType});

  /// Starts from [assigned]; zero starts empty, showing 0.00 as a hint.
  factory AssignDraft.start(Money assigned) => AssignDraft._(
    assigned.isZero ? '' : MoneyFormatter.formatForInput(assigned),
    replaceOnType: true,
  );

  /// The longest text accepted, far beyond any real sum.
  static const int maxLength = 40;

  final String text;

  /// Whether the next amount typed replaces [text] instead of extending it.
  final bool replaceOnType;

  /// The draft after [key]. [currencyCode] is used by [AssignKey.equals],
  /// which shows the result, or leaves an invalid sum for [evaluate] to
  /// report.
  AssignDraft press(AssignKey key, {required String currencyCode}) {
    switch (key) {
      case AssignKey.backspace:
        return AssignDraft._(
          text.isEmpty ? '' : text.substring(0, text.length - 1),
          replaceOnType: false,
        );
      case AssignKey.equals:
        try {
          final result = evaluate(currencyCode: currencyCode);
          return AssignDraft.start(result);
        } on Object {
          return this;
        }
      case AssignKey.plus || AssignKey.minus:
        // Amounts are entered positive: a sum cannot start with an operator.
        if (text.isEmpty) return const AssignDraft._('', replaceOnType: false);
        final last = text[text.length - 1];
        final base = last == '+' || last == '-'
            ? text.substring(0, text.length - 1)
            : text;
        return _withText('$base${key.character}');
      default:
        final character = key.character!;
        if (replaceOnType) {
          return _withText(character == '.' ? '0.' : character);
        }
        return _withText('$text$character');
    }
  }

  AssignDraft _withText(String next) => next.length > maxLength
      ? AssignDraft._(text, replaceOnType: false)
      : AssignDraft._(next, replaceOnType: false);

  /// Replaces the draft with [amount], ready to be replaced again.
  AssignDraft fill(Money amount) => AssignDraft.start(amount);

  /// The amount the draft evaluates to; empty means zero.
  ///
  /// Throws [MoneyParseException] for an incomplete or invalid sum, and
  /// [AssignBelowZeroException] when the result is negative.
  Money evaluate({required String currencyCode}) {
    if (text.isEmpty) return Money.zero(currencyCode);
    final result = evaluateMoneyExpression(text, currencyCode: currencyCode);
    if (result.isNegative) throw const AssignBelowZeroException();
    return result;
  }
}

/// The sum came to less than zero; Assigned cannot be negative.
class AssignBelowZeroException implements Exception {
  const AssignBelowZeroException();
}
