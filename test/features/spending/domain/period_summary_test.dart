import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/spending/domain/period_summary.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';

import '../../transactions/domain/transaction_fixtures.dart';

TransactionDraft on(CalendarDate date, TransactionDraft draft) =>
    TransactionDraft(
      type: draft.type,
      amount: draft.amount,
      date: date,
      payee: draft.payee,
      categoryId: draft.categoryId,
      sourceAccountId: draft.sourceAccountId,
      destinationAccountId: draft.destinationAccountId,
    );

void main() {
  final november = DateRange.monthOf(CalendarDate(2026, 11, 16));

  group('periodTotals', () {
    test('sums spending and inflow in the period', () {
      final totals = periodTotals([
        inflow(amount: 3000000),
        spending(amount: 50000),
        spending(from: walletId, amount: 15000),
      ], november);

      expect(totals.inflow, php(3000000));
      expect(totals.spending, php(65000));
    });

    test('is zero with no transactions', () {
      final totals = periodTotals(const [], november);

      expect(totals.inflow, php(0));
      expect(totals.spending, php(0));
    });

    group('Rule 5: transfers and card payments are excluded', () {
      test('from spending and from inflow', () {
        final totals = periodTotals([
          transfer(amount: 200000),
          transfer(to: carLoanId, amount: 500000),
          cardPayment(amount: 300000),
        ], november);

        expect(totals.spending, php(0));
        expect(totals.inflow, php(0));
      });

      test('a cash advance (transfer from credit) is neither', () {
        final totals = periodTotals([
          transfer(from: rcbcCardId, to: bdoId, amount: 260000),
        ], november);

        expect(totals.spending, php(0));
        expect(totals.inflow, php(0));
      });
    });

    test('Rule 6: a card purchase counts once, its payment not again', () {
      final totals = periodTotals([
        spending(from: rcbcCardId, amount: 120000),
        cardPayment(amount: 120000),
      ], november);

      expect(totals.spending, php(120000));
    });

    test('a card refund (inflow to credit) counts as inflow', () {
      final totals = periodTotals([
        inflow(to: rcbcCardId, amount: 5000, category: null),
      ], november);

      expect(totals.inflow, php(5000));
    });

    group('period boundaries are inclusive', () {
      test('first and last day count; the days around them do not', () {
        final totals = periodTotals([
          on(CalendarDate(2026, 10, 31), spending(amount: 1)),
          on(CalendarDate(2026, 11, 1), spending(amount: 10)),
          on(CalendarDate(2026, 11, 30), spending(amount: 100)),
          on(CalendarDate(2026, 12, 1), spending(amount: 1000)),
          on(CalendarDate(2026, 10, 31), inflow(amount: 2)),
          on(CalendarDate(2026, 11, 30), inflow(amount: 20)),
        ], november);

        expect(totals.spending, php(110));
        expect(totals.inflow, php(20));
      });
    });

    test('transactions on archived accounts still count', () {
      final totals = periodTotals([
        spending(from: oldWalletId, amount: 700),
      ], november);

      expect(totals.spending, php(700));
    });
  });

  group('summarizeBalances (D2)', () {
    Account withOpening(String id, int openingMinor) =>
        accounts[id]!.copyWith(openingBalance: php(openingMinor));

    final all = [
      withOpening(bdoId, 1500000),
      withOpening(walletId, 250000),
      withOpening(rcbcCardId, -300000),
      withOpening(carLoanId, -5000000),
      withOpening(oldWalletId, 99900), // archived
    ];

    test('active Savings/Cash total; archived accounts excluded (G7)', () {
      final summary = summarizeBalances(all, balancesFor(all, const []));

      expect(summary.availableMoney, php(1750000));
      expect(summary.creditOwed, php(300000));
      expect(summary.loansOwed, php(5000000));
    });

    test('follows transactions through the balance function', () {
      final balances = balancesFor(all, [
        spending(from: rcbcCardId, amount: 50000), // owe 500 more
        cardPayment(amount: 350000), // pay the card in full
        transfer(to: carLoanId, amount: 1000000), // loan payment
      ]);

      final summary = summarizeBalances(all, balances);

      expect(summary.creditOwed, php(0));
      expect(summary.loansOwed, php(4000000));
      expect(summary.availableMoney, php(1750000 - 350000 - 1000000));
    });

    test('a cash advance raises available money and credit owed equally', () {
      final balances = balancesFor(all, [
        transfer(from: rcbcCardId, to: bdoId, amount: 260000),
      ]);

      expect(balances[rcbcCardId], php(-560000));
      expect(balances[bdoId], php(1760000));
      final summary = summarizeBalances(all, balances);
      expect(summary.availableMoney, php(1750000 + 260000));
      expect(summary.creditOwed, php(300000 + 260000));
    });

    test('an overdrawn account lowers available money', () {
      final overdrawn = [withOpening(bdoId, 0)];
      final balances = balancesFor(overdrawn, [spending(amount: 1000)]);

      expect(summarizeBalances(overdrawn, balances).availableMoney, php(-1000));
    });

    test('no accounts gives zeros', () {
      expect(
        summarizeBalances(const [], const {}),
        BalanceSummary(
          availableMoney: php(0),
          creditOwed: php(0),
          loansOwed: php(0),
        ),
      );
    });
  });
}
