import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_effects.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import 'transaction_fixtures.dart';

/// Sums the effects of [transactions] per account, starting from zero.
Map<String, Money> applyAll(List<TransactionDraft> transactions) {
  final balances = <String, Money>{};
  for (final effect in transactions.expand(effectsOf)) {
    balances[effect.accountId] =
        (balances[effect.accountId] ?? php(0)) + effect.change;
  }
  return balances;
}

void main() {
  group('Rule 1: spending decreases the account used', () {
    test('from a savings account', () {
      expect(effectsOf(spending(amount: 50000)), [
        (accountId: bdoId, change: php(-50000)),
      ]);
    });
  });

  group('Rule 2: inflow increases the receiving account', () {
    test('into a savings account', () {
      expect(effectsOf(inflow(amount: 3000000)), [
        (accountId: bdoId, change: php(3000000)),
      ]);
    });
  });

  group('Rule 3: transfer moves the same amount between accounts', () {
    test('source decreases and destination increases equally', () {
      final effects = effectsOf(transfer(amount: 200000));

      expect(effects, [
        (accountId: bdoId, change: php(-200000)),
        (accountId: walletId, change: php(200000)),
      ]);
      expect(effects.first.change + effects.last.change, php(0));
    });

    test('a loan payment reduces the amount owed (G4)', () {
      expect(effectsOf(transfer(to: carLoanId, amount: 1000000)), [
        (accountId: bdoId, change: php(-1000000)),
        (accountId: carLoanId, change: php(1000000)),
      ]);
    });
  });

  group('Rule 4: card payment reduces cash and the amount owed', () {
    test('asset decreases; credit balance moves towards zero', () {
      // RCBC owes 3,000 (balance -300000) before the payment.
      final balances = applyAll([cardPayment(amount: 300000)]);
      final rcbcAfter = php(-300000) + balances[rcbcCardId]!;

      expect(balances[bdoId], php(-300000));
      expect(rcbcAfter, php(0));
    });
  });

  group('Rule 6: a card purchase increases the amount owed', () {
    test('spending on a credit account makes its balance more negative', () {
      expect(effectsOf(spending(from: rcbcCardId, amount: 50000)), [
        (accountId: rcbcCardId, change: php(-50000)),
      ]);
    });

    test('purchase then payment: cash pays once, card ends at zero', () {
      final balances = applyAll([
        spending(from: rcbcCardId, amount: 50000),
        cardPayment(amount: 50000),
      ]);

      expect(balances[rcbcCardId], php(0));
      expect(balances[bdoId], php(-50000));
    });
  });

  group('Rule 5: only spending and inflow count in totals', () {
    test('countsAsSpending', () {
      expect(TransactionType.spending.countsAsSpending, isTrue);
      expect(TransactionType.inflow.countsAsSpending, isFalse);
      expect(TransactionType.transfer.countsAsSpending, isFalse);
      expect(TransactionType.creditCardPayment.countsAsSpending, isFalse);
    });

    test('countsAsInflow', () {
      expect(TransactionType.inflow.countsAsInflow, isTrue);
      expect(TransactionType.spending.countsAsInflow, isFalse);
      expect(TransactionType.transfer.countsAsInflow, isFalse);
      expect(TransactionType.creditCardPayment.countsAsInflow, isFalse);
    });
  });

  test('a multi-transaction scenario nets out correctly', () {
    final balances = applyAll([
      inflow(amount: 3000000), // salary into BDO
      transfer(amount: 200000), // BDO -> wallet
      spending(from: walletId, amount: 15000), // lunch from wallet
      spending(from: rcbcCardId, amount: 120000), // card purchase
      cardPayment(amount: 120000), // pay card in full
      transfer(to: carLoanId, amount: 500000), // loan payment
    ]);

    expect(balances[bdoId], php(3000000 - 200000 - 120000 - 500000));
    expect(balances[walletId], php(200000 - 15000));
    expect(balances[rcbcCardId], php(0));
    expect(balances[carLoanId], php(500000));
  });

  test('throws when a required account is missing', () {
    expect(() => effectsOf(spending(from: null)), throwsStateError);
    expect(() => effectsOf(inflow(to: null)), throwsStateError);
  });
}
