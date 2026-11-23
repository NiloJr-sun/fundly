import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/spending/domain/period_summary.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  final budget = accounts[bdoId]!.copyWith(openingBalance: php(1000000));
  final december = CalendarMonth(2026, 12);

  TransactionDraft entry(
    TransactionType type,
    int amount,
    CalendarDate date, {
    String? from,
    String? to,
  }) => TransactionDraft(
    type: type,
    amount: php(amount),
    date: date,
    sourceAccountId: from,
    destinationAccountId: to,
    categoryId: type == TransactionType.spending ? foodId : null,
  );

  ReadyToAssign summarize(
    List<TransactionDraft> entries, {
    CalendarMonth? month,
    List<MonthlyPlan> plans = const [],
  }) => readyToAssign(
    month: month ?? december,
    budgetAccount: budget,
    plans: plans,
    transactions: entries,
    categories: categories.values,
  );

  test('opening money survives a month without transactions', () {
    final result = summarize([]);
    expect(result.carryOver, php(1000000));
    expect(result.moneyIn, php(0));
    expect(result.amount, php(1000000));
  });

  test(
    'previous closing balance is shown once, not added to the account again',
    () {
      final entries = [
        spending(amount: 400000, date: CalendarDate(2026, 11, 30)),
      ];
      final result = summarize(entries);
      expect(result.carryOver, php(600000));
      expect(result.amount, php(600000));
      expect(currentBalance(budget, entries), php(600000));
      expect(
        summarize(entries),
        result,
        reason: 'Repeated rollover calculations are idempotent',
      );
      expect(periodTotals(entries, december.dateRange), (
        inflow: php(0),
        spending: php(0),
      ));
    },
  );

  test('first-day transactions are excluded from carry-over', () {
    final result = summarize([
      entry(
        TransactionType.inflow,
        100000,
        CalendarDate(2026, 11, 30),
        to: bdoId,
      ),
      spending(amount: 200000, date: CalendarDate(2026, 12, 1)),
      entry(
        TransactionType.inflow,
        300000,
        CalendarDate(2027, 1, 1),
        to: bdoId,
      ),
    ]);
    expect(result.carryOver, php(1100000));
    expect(result.moneyIn, php(0));
    expect(result.amount, php(1100000));
  });

  test('all previous account movements count; other accounts do not', () {
    final date = CalendarDate(2026, 11, 30);
    final result = summarize([
      entry(TransactionType.inflow, 100000, date, to: bdoId),
      entry(TransactionType.transfer, 50000, date, from: walletId, to: bdoId),
      entry(TransactionType.transfer, 20000, date, from: bdoId, to: walletId),
      entry(
        TransactionType.creditCardPayment,
        30000,
        date,
        from: bdoId,
        to: rcbcCardId,
      ),
      spending(amount: 100000, date: date),
      entry(TransactionType.inflow, 900000, date, to: walletId),
      spending(amount: 800000, date: date, from: rcbcCardId),
    ]);
    expect(result.carryOver, php(1000000));
  });

  test(
    'missed months are reconstructed without needing intermediate rollovers',
    () {
      final entries = [
        spending(amount: 100000, date: CalendarDate(2026, 11, 30)),
        spending(amount: 200000, date: CalendarDate(2026, 12, 31)),
        spending(amount: 300000, date: CalendarDate(2027, 1, 31)),
      ];
      expect(
        summarize(entries, month: CalendarMonth(2027, 2)).carryOver,
        php(400000),
      );
    },
  );

  test('December closes into January across the year boundary', () {
    final result = summarize([
      spending(amount: 100000, date: CalendarDate(2026, 12, 31)),
      spending(amount: 200000, date: CalendarDate(2027, 1, 1)),
    ], month: CalendarMonth(2027, 1));
    expect(result.carryOver, php(900000));
    expect(result.amount, php(900000));
  });

  test('leap-day spending is included in March opening money', () {
    final result = summarize([
      spending(amount: 100000, date: CalendarDate(2028, 2, 29)),
      spending(amount: 200000, date: CalendarDate(2028, 3, 1)),
    ], month: CalendarMonth(2028, 3));
    expect(result.carryOver, php(900000));
  });

  test(
    'earlier edits, deletes and opening-balance edits recalculate carry-over',
    () {
      final date = CalendarDate(2026, 11, 30);
      expect(
        summarize([spending(amount: 100000, date: date)]).carryOver,
        php(900000),
      );
      expect(
        summarize([spending(amount: 200000, date: date)]).carryOver,
        php(800000),
      );
      expect(summarize([]).carryOver, php(1000000));
      expect(
        readyToAssign(
          month: december,
          budgetAccount: budget.copyWith(openingBalance: php(2000000)),
          plans: [],
          transactions: [],
          categories: categories.values,
        ).carryOver,
        php(2000000),
      );
    },
  );

  test(
    'switching budget accounts uses that account ledger, not the former one',
    () {
      final other = accounts[walletId]!.copyWith(openingBalance: php(50000));
      final result = readyToAssign(
        month: december,
        budgetAccount: other,
        plans: [],
        categories: categories.values,
        transactions: [
          spending(amount: 900000, date: CalendarDate(2026, 11, 30)),
          entry(
            TransactionType.transfer,
            10000,
            CalendarDate(2026, 11, 30),
            from: bdoId,
            to: walletId,
          ),
        ],
      );
      expect(result.carryOver, php(60000));
    },
  );

  test('only money carries forward, not previous targets or assignments', () {
    final now = DateTime.utc(2026, 11);
    final result = summarize(
      [],
      plans: [
        MonthlyPlan(
          id: '1',
          month: december.previous,
          categoryId: foodId,
          target: php(500000),
          assigned: php(400000),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    expect(result.carryOver, php(1000000));
    expect(result.assigned, php(0));
    expect(result.amount, php(1000000));
  });

  test(
    'zero and negative closing balances remain signed, with exact centavos',
    () {
      expect(
        summarize([spending(amount: 1000000, date: CalendarDate(2026, 11, 30))])
            .carryOver,
        php(0),
      );
      expect(
        summarize([spending(amount: 1000001, date: CalendarDate(2026, 11, 30))])
            .carryOver,
        php(-1),
      );
    },
  );
}
