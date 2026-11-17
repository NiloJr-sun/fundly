import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';

import '../../transactions/domain/transaction_fixtures.dart';

Account withOpening(Account account, int openingMinor) =>
    account.copyWith(openingBalance: php(openingMinor));

void main() {
  // BDO starts with 15,000; RCBC owes 3,000; the car loan owes 50,000.
  final bdo = withOpening(accounts[bdoId]!, 1500000);
  final wallet = accounts[walletId]!;
  final rcbc = withOpening(accounts[rcbcCardId]!, -300000);
  final carLoan = withOpening(accounts[carLoanId]!, -5000000);
  final all = [bdo, wallet, rcbc, carLoan];

  Map<int, Money> balances(List<TransactionDraft> transactions) =>
      balancesFor(all, transactions);

  test('with no transactions, balance is the opening balance', () {
    expect(balances(const []), {
      bdoId: php(1500000),
      walletId: php(0),
      rcbcCardId: php(-300000),
      carLoanId: php(-5000000),
    });
  });

  group('D1 table', () {
    test('Spending decreases the source account (rule 1)', () {
      expect(balances([spending(amount: 50000)])[bdoId], php(1450000));
    });

    test('Inflow increases the destination account (rule 2)', () {
      expect(balances([inflow(amount: 3000000)])[bdoId], php(4500000));
    });

    test('Transfer moves the same amount (rule 3)', () {
      final result = balances([transfer(amount: 200000)]);

      expect(result[bdoId], php(1300000));
      expect(result[walletId], php(200000));
    });

    test('Card payment reduces cash and the amount owed (rule 4)', () {
      final result = balances([cardPayment(amount: 300000)]);

      expect(result[bdoId], php(1200000));
      expect(result[rcbcCardId], php(0));
    });

    test('Card purchase increases the amount owed (rule 6)', () {
      expect(
        balances([spending(from: rcbcCardId, amount: 50000)])[rcbcCardId],
        php(-350000),
      );
    });

    test('Loan payment by transfer reduces the amount owed (G4)', () {
      expect(
        balances([transfer(to: carLoanId, amount: 1000000)])[carLoanId],
        php(-4000000),
      );
    });
  });

  group('Rule 11: editing or deleting recalculates', () {
    final original = spending(amount: 50000);

    test('changing the amount', () {
      expect(balances([original])[bdoId], php(1450000));
      expect(balances([spending(amount: 80000)])[bdoId], php(1420000));
    });

    test('moving to a different account', () {
      final moved = balances([spending(from: walletId, amount: 50000)]);

      expect(moved[bdoId], php(1500000));
      expect(moved[walletId], php(-50000));
    });

    test('deleting restores the previous balance', () {
      expect(balances([original, transfer()])[bdoId], php(1250000));
      expect(balances([transfer()])[bdoId], php(1300000));
    });
  });

  test('multi-transaction month', () {
    final result = balances([
      inflow(amount: 3000000), // salary
      transfer(amount: 200000), // to wallet
      spending(from: walletId, amount: 15000), // lunch
      spending(from: rcbcCardId, amount: 120000), // card purchase
      cardPayment(amount: 420000), // pay card in full (3,000 + 1,200)
      transfer(to: carLoanId, amount: 500000), // loan payment
    ]);

    expect(result, {
      bdoId: php(1500000 + 3000000 - 200000 - 420000 - 500000),
      walletId: php(200000 - 15000),
      rcbcCardId: php(0),
      carLoanId: php(-4500000),
    });
  });

  test('effects on accounts outside the list are ignored', () {
    expect(balancesFor([bdo], [transfer()]), {bdoId: php(1300000)});
  });

  test('currentBalance matches balancesFor', () {
    final transactions = [spending(), transfer()];

    expect(
      currentBalance(bdo, transactions),
      balancesFor(all, transactions)[bdoId],
    );
  });

  group('needsArchiveConfirmation', () {
    test('not needed for a zero balance', () {
      expect(needsArchiveConfirmation(php(0)), isFalse);
    });

    test('needed when money is held or owed', () {
      expect(needsArchiveConfirmation(php(1)), isTrue);
      expect(needsArchiveConfirmation(php(-500000)), isTrue);
    });
  });

  test('account type does not change the arithmetic', () {
    for (final type in AccountType.values) {
      final account = Account(
        id: 1,
        name: 'Any',
        type: type,
        openingBalance: php(-100),
        createdAt: DateTime.utc(2026, 11, 16),
      );
      expect(currentBalance(account, const []), php(-100), reason: type.name);
    }
  });

  group('totalsByType', () {
    test('sums signed balances per type, zero for types without accounts', () {
      final totals = totalsByType(
        [bdo, wallet, rcbc],
        {bdoId: php(1500000), walletId: php(250050), rcbcCardId: php(-300000)},
      );

      expect(totals, {
        AccountType.savingsCash: php(1750050),
        AccountType.credit: php(-300000),
        AccountType.loan: php(0),
      });
    });

    test('only counts the given accounts; missing balances are skipped', () {
      final totals = totalsByType(
        [bdo, carLoan],
        {bdoId: php(100), walletId: php(999), rcbcCardId: php(-999)},
      );

      expect(totals[AccountType.savingsCash], php(100));
      expect(totals[AccountType.credit], php(0));
      expect(totals[AccountType.loan], php(0));
    });
  });
}
