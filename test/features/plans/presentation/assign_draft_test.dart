import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/money/money_parser.dart';
import 'package:fundly/features/plans/presentation/assign_draft.dart';

void main() {
  Money php(int minorUnits) =>
      Money(minorUnits: minorUnits, currencyCode: 'PHP');

  AssignDraft press(AssignDraft draft, List<AssignKey> keys) {
    var result = draft;
    for (final key in keys) {
      result = result.press(key, currencyCode: 'PHP');
    }
    return result;
  }

  const k1 = AssignKey.digit1;
  const k2 = AssignKey.digit2;
  const k5 = AssignKey.digit5;
  const k0 = AssignKey.digit0;

  test('starts from the current amount, ready to be replaced', () {
    final draft = AssignDraft.start(php(1000000));

    expect(draft.text, '10000.00');
    expect(draft.replaceOnType, isTrue);
    expect(AssignDraft.start(php(0)).text, isEmpty);
  });

  test('typing an amount replaces the current one', () {
    final draft = press(AssignDraft.start(php(1000000)), [k5, k0, k0]);

    expect(draft.text, '500');
    expect(draft.evaluate(currencyCode: 'PHP'), php(50000));
  });

  test('a decimal point first starts at 0.', () {
    final draft = press(AssignDraft.start(php(1000000)), [
      AssignKey.decimalPoint,
      k5,
    ]);

    expect(draft.text, '0.5');
  });

  test('an operator continues from the current amount', () {
    final draft = press(AssignDraft.start(php(1000000)), [
      AssignKey.plus,
      k5,
      k0,
      k0,
    ]);

    expect(draft.text, '10000.00+500');
    expect(draft.evaluate(currencyCode: 'PHP'), php(1050000));
  });

  test('a second operator replaces the first', () {
    final draft = press(AssignDraft.start(php(100)), [
      AssignKey.plus,
      AssignKey.minus,
    ]);

    expect(draft.text, '1.00-');
  });

  test('a sum cannot start with an operator', () {
    final draft = press(AssignDraft.start(php(0)), [AssignKey.minus, k5]);

    expect(draft.text, '5');
  });

  test('equals shows the result, which the next amount replaces', () {
    final summed = press(AssignDraft.start(php(0)), [
      k1,
      k2,
      AssignKey.plus,
      k5,
      AssignKey.equals,
    ]);
    expect(summed.text, '17.00');
    expect(summed.replaceOnType, isTrue);

    expect(press(summed, [k2]).text, '2');
  });

  test('equals leaves an unfinished sum as it is', () {
    final draft = press(AssignDraft.start(php(0)), [
      k5,
      AssignKey.plus,
      AssignKey.equals,
    ]);

    expect(draft.text, '5+');
    expect(
      () => draft.evaluate(currencyCode: 'PHP'),
      throwsA(isA<MoneyParseException>()),
    );
  });

  test('backspace removes the last character and keeps the rest', () {
    final draft = press(AssignDraft.start(php(1000000)), [
      AssignKey.backspace,
      AssignKey.backspace,
      AssignKey.backspace,
    ]);

    expect(draft.text, '10000');
    expect(draft.replaceOnType, isFalse);
    expect(press(draft, [k5]).text, '100005');
    expect(
      press(AssignDraft.start(php(0)), [AssignKey.backspace]).text,
      isEmpty,
    );
  });

  test('empty is zero; below zero is refused', () {
    expect(AssignDraft.start(php(0)).evaluate(currencyCode: 'PHP'), php(0));
    final negative = press(AssignDraft.start(php(100)), [AssignKey.minus, k5]);
    expect(
      () => negative.evaluate(currencyCode: 'PHP'),
      throwsA(isA<AssignBelowZeroException>()),
    );
  });

  test('fill replaces the draft with an amount', () {
    final draft = press(AssignDraft.start(php(0)), [k5]).fill(php(2400000));

    expect(draft.text, '24000.00');
    expect(draft.replaceOnType, isTrue);
  });

  test('stops growing past the longest text', () {
    var draft = press(AssignDraft.start(php(0)), [k1]);
    for (var i = 0; i < 60; i++) {
      draft = draft.press(k1, currencyCode: 'PHP');
    }

    expect(draft.text.length, AssignDraft.maxLength);
  });
}
