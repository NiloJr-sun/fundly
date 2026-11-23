import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_filter.dart';

import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  final month = CalendarMonth(2026, 11);
  const card = Category(
    id: '101',
    name: 'RCBC',
    kind: CategoryKind.spending,
    planGroup: PlanGroup.liability,
    linkedAccountId: rcbcCardId,
  );
  const loan = Category(
    id: '102',
    name: 'Car loan',
    kind: CategoryKind.spending,
    planGroup: PlanGroup.liability,
    linkedAccountId: carLoanId,
  );
  final allCategories = [categories[foodId]!, card, loan];
  MonthlyPlan plan(String categoryId, int assigned) => MonthlyPlan(
    id: categoryId,
    month: month,
    categoryId: categoryId,
    target: null,
    assigned: php(assigned),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  List<CategoryPlanSummary> summarize(
    List<TransactionDraft> transactions, {
    List<MonthlyPlan> plans = const [],
  }) => planSummaries(
    month: month,
    categories: allCategories,
    plans: plans,
    transactions: transactions,
  );

  test('active debts appear without a saved plan or inferred target', () {
    final rows = summarize([]);
    expect(rows.map((r) => r.category.id), [foodId, card.id, loan.id]);
    expect(rows[1].target, isNull);
    expect(rows[1].assigned, php(0));
    expect(rows[1].hasPlan, isFalse);
  });

  test(
    'card payments and loan transfers are activity, purchases stay in Food',
    () {
      final rows = summarize([
        cardPayment(amount: 20000),
        transfer(amount: 30000, to: carLoanId),
        spending(amount: 50000, from: rcbcCardId),
        inflow(amount: 10000, to: rcbcCardId),
        transfer(amount: 10000),
        spending(amount: 10000, date: CalendarDate(2026, 10, 31)),
      ]);
      expect(rows[0].activity, php(50000));
      expect(rows[1].activity, php(20000));
      expect(rows[2].activity, php(30000));
    },
  );

  test('card and loan payments are row Activity, not moved out', () {
    final result = readyToAssign(
      month: month,
      budgetAccount: accounts[bdoId]!,
      categories: allCategories,
      plans: [plan(card.id, 40000), plan(loan.id, 30000)],
      transactions: [
        inflow(amount: 100000),
        cardPayment(amount: 10000),
        transfer(amount: 20000, to: carLoanId),
      ],
    );
    expect(result.moneyIn, php(100000));
    expect(result.movedOut, php(0));
    expect(result.assigned, php(70000));
    expect(result.amount, php(30000));
  });

  test('payments from other accounts do not change Ready to assign', () {
    final transactions = [cardPayment(amount: 20000, from: walletId)];
    final row = summarize(transactions, plans: [plan(card.id, 40000)])[1];
    expect(row.activity, php(20000));
    expect(row.available, php(20000));
    final result = readyToAssign(
      month: month,
      budgetAccount: accounts[bdoId]!,
      categories: allCategories,
      plans: [plan(card.id, 40000)],
      transactions: [inflow(amount: 100000), ...transactions],
    );
    expect(result.amount, php(60000));
  });

  test('overpaying a debt row leaves Ready to assign unchanged', () {
    final result = readyToAssign(
      month: month,
      budgetAccount: accounts[bdoId]!,
      categories: allCategories,
      plans: [plan(card.id, 10000), plan(loan.id, 30000)],
      transactions: [inflow(amount: 100000), cardPayment(amount: 20000)],
    );
    expect(result.assigned, php(40000));
    expect(result.amount, php(60000));
  });

  test(
    'payment Activity filter excludes purchases, inflows and other accounts',
    () {
      final filter = TransactionFilter(
        dateRange: month.dateRange,
        accountId: rcbcCardId,
        paymentAccountId: rcbcCardId,
      );
      final payment = cardPayment(amount: 10000);
      expect(
        filter.apply([
          payment,
          spending(from: rcbcCardId),
          inflow(to: rcbcCardId),
          transfer(to: carLoanId),
        ]),
        [payment],
      );
      expect(filter.withDateRange(null).paymentAccountId, rcbcCardId);
      expect(filter.withAccount(walletId).paymentAccountId, isNull);
      expect(filter.withCategory(foodId).paymentAccountId, isNull);
      expect(filter.withoutPaymentFilter().paymentAccountId, isNull);
      expect(
        filter,
        isNot(
          TransactionFilter(dateRange: month.dateRange, accountId: rcbcCardId),
        ),
      );
    },
  );
}
