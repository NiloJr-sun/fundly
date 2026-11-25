import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/spending/domain/period_summary.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import '../../transactions/domain/transaction_fixtures.dart';

/// Card purchases move covered money to the card's Plans row, as YNAB does.
void main() {
  final november = CalendarMonth(2026, 11);
  final december = CalendarMonth(2026, 12);
  final nov10 = CalendarDate(2026, 11, 10);
  final nov20 = CalendarDate(2026, 11, 20);
  final dec5 = CalendarDate(2026, 12, 5);

  const cardRow = Category(
    id: '101',
    name: 'RCBC',
    kind: CategoryKind.spending,
    planGroup: PlanGroup.liability,
    linkedAccountId: rcbcCardId,
  );
  const loanRow = Category(
    id: '102',
    name: 'Car loan',
    kind: CategoryKind.spending,
    planGroup: PlanGroup.liability,
    linkedAccountId: carLoanId,
  );
  const transport = Category(
    id: '11',
    name: 'Transport',
    kind: CategoryKind.spending,
  );
  final allCategories = [
    categories[foodId]!,
    transport,
    categories[salaryId]!,
    cardRow,
    loanRow,
  ];
  final budget = accounts[bdoId]!.copyWith(openingBalance: php(1000000));
  final allAccounts = [
    for (final account in accounts.values)
      if (account.id == bdoId) budget else account,
  ];

  MonthlyPlan plan(String categoryId, int assigned, [CalendarMonth? month]) =>
      MonthlyPlan(
        id: '$categoryId-${month ?? november}',
        month: month ?? november,
        categoryId: categoryId,
        target: null,
        assigned: php(assigned),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  TransactionDraft cardPurchase(
    int amount, {
    CalendarDate? date,
    String? category = foodId,
    String card = rcbcCardId,
  }) => spending(amount: amount, from: card, category: category, date: date);

  TransactionDraft payCard(int amount, {CalendarDate? date}) =>
      TransactionDraft(
        type: TransactionType.creditCardPayment,
        amount: php(amount),
        date: date ?? nov20,
        sourceAccountId: bdoId,
        destinationAccountId: rcbcCardId,
      );

  List<CategoryPlanSummary> rows(
    List<TransactionDraft> transactions, {
    List<MonthlyPlan> plans = const [],
    CalendarMonth? month,
  }) => planSummaries(
    month: month ?? november,
    categories: allCategories,
    plans: plans,
    transactions: transactions,
    accounts: allAccounts,
  );

  CategoryPlanSummary row(List<CategoryPlanSummary> rows, String id) =>
      rows.singleWhere((row) => row.category.id == id);

  ReadyToAssign ready(
    List<TransactionDraft> transactions, {
    List<MonthlyPlan> plans = const [],
    CalendarMonth? month,
  }) => readyToAssign(
    month: month ?? november,
    budgetAccounts: [budget],
    plans: plans,
    transactions: transactions,
    categories: allCategories,
    accounts: allAccounts,
  );

  group('a covered purchase', () {
    test('leaves the category and moves to the card row', () {
      final result = rows(
        [cardPurchase(50000)],
        plans: [plan(foodId, 500000), plan(cardRow.id, 100000)],
      );
      final food = row(result, foodId);
      expect(food.activity, php(50000));
      expect(food.available, php(450000));
      final card = row(result, cardRow.id);
      expect(card.assigned, php(100000), reason: 'Assigned stays manual');
      expect(card.movedIn, php(50000));
      expect(card.carriedOver, php(0));
      expect(card.available, php(150000));
    });

    test('paying the card brings the card row back; counted once', () {
      final transactions = [cardPurchase(50000), payCard(50000)];
      final plans = [plan(foodId, 500000), plan(cardRow.id, 100000)];
      final result = rows(transactions, plans: plans);
      expect(row(result, foodId).available, php(450000));
      expect(row(result, cardRow.id).activity, php(50000));
      expect(row(result, cardRow.id).available, php(100000));

      // Ready to assign: the opening ₱10,000 minus ₱6,000 assigned; neither
      // the purchase nor the payment changes it.
      expect(ready(transactions, plans: plans).amount, php(400000));
    });

    test('only card rows get moved-in and carried-over figures', () {
      final result = rows([cardPurchase(50000)], plans: [plan(foodId, 1)]);
      expect(row(result, foodId).movedIn, isNull);
      expect(row(result, loanRow.id).movedIn, isNull);
      expect(row(result, loanRow.id).carriedOver, isNull);
    });
  });

  group('a partly covered purchase', () {
    test('moves only what the category had; the category is overspent', () {
      final result = rows([cardPurchase(50000)], plans: [plan(foodId, 20000)]);
      final food = row(result, foodId);
      expect(food.available, php(-30000));
      expect(food.status, PlanStatus.overspent);
      expect(row(result, cardRow.id).movedIn, php(20000));
    });

    test('nothing assigned moves nothing', () {
      final result = rows([cardPurchase(50000)]);
      expect(row(result, cardRow.id).movedIn, php(0));
      expect(row(result, foodId).available, php(-50000));
    });

    test('the uncovered part shows as overspending on the card row when '
        'paid', () {
      final result = rows(
        [cardPurchase(50000), payCard(50000)],
        plans: [plan(foodId, 20000)],
      );
      expect(row(result, cardRow.id).available, php(-30000));
      expect(row(result, cardRow.id).status, PlanStatus.overspent);
    });
  });

  group('order within a month', () {
    test('by date: earlier cash spending uses up Available first', () {
      final result = rows(
        [
          cardPurchase(30000, date: nov20),
          spending(amount: 40000, date: nov10),
        ],
        plans: [plan(foodId, 50000)],
      );
      expect(row(result, cardRow.id).movedIn, php(10000));
    });

    test('a later cash purchase does not take back moved money', () {
      final result = rows(
        [
          cardPurchase(30000, date: nov10),
          spending(amount: 40000, date: nov20),
        ],
        plans: [plan(foodId, 50000)],
      );
      expect(row(result, cardRow.id).movedIn, php(30000));
      expect(row(result, foodId).available, php(-20000));
    });

    test('same day: by when each was recorded', () {
      final cash = saved(
        spending(amount: 40000, date: nov10),
        id: 'cash',
        createdAt: DateTime.utc(2026, 11, 10, 8),
      );
      final card = saved(
        cardPurchase(30000, date: nov10),
        id: 'card',
        createdAt: DateTime.utc(2026, 11, 10, 9),
      );
      // Given newest first, as the repositories list them.
      final result = rows([card, cash], plans: [plan(foodId, 50000)]);
      expect(row(result, cardRow.id).movedIn, php(10000));
    });

    test('each category is covered from its own Available', () {
      final result = rows(
        [cardPurchase(30000), cardPurchase(30000, category: transport.id)],
        plans: [plan(foodId, 50000), plan(transport.id, 10000)],
      );
      expect(row(result, cardRow.id).movedIn, php(40000));
    });
  });

  group('carry over to the next month', () {
    final transactions = [
      cardPurchase(50000, date: nov10),
      payCard(50000, date: dec5),
    ];
    final plans = [plan(foodId, 500000)];

    test('unpaid moved money carries; the payment is covered', () {
      final result = rows(transactions, plans: plans, month: december);
      final card = row(result, cardRow.id);
      expect(card.carriedOver, php(50000));
      expect(card.movedIn, php(0));
      expect(card.activity, php(50000));
      expect(card.available, php(0));
      expect(card.isOverspent, isFalse);
    });

    test('once paid, nothing carries further', () {
      final result = rows(
        transactions,
        plans: plans,
        month: CalendarMonth(2027, 1),
      );
      expect(row(result, cardRow.id).carriedOver, php(0));
    });

    test('Ready to assign holds the carried money for the card', () {
      // November: ₱10,000 opening, ₱5,000 assigned.
      expect(ready(transactions, plans: plans).amount, php(500000));
      // December: the ₱10,000 is still in the bank on Dec 1, but ₱500 of it
      // is promised to the card, so only ₱9,500 is free. Food's unspent
      // ₱4,500 returns, as it always has.
      final december = ready(
        transactions,
        plans: plans,
        month: CalendarMonth(2026, 12),
      );
      expect(december.carryOver, php(1000000));
      expect(december.heldForCards, php(50000));
      expect(december.amount, php(950000));
    });

    test('no double counting: free money plus what Plans holds is the '
        'cash', () {
      // December, before the payment: the purchase did not touch the bank.
      final purchaseOnly = [cardPurchase(50000, date: nov10)];
      final cash = currentBalance(budget, purchaseOnly);
      final free = ready(purchaseOnly, plans: plans, month: december).amount;
      final held = row(
        rows(purchaseOnly, plans: plans, month: december),
        cardRow.id,
      ).available;
      expect(held, php(50000));
      expect(free + held, cash);
    });

    test('a partial payment carries the rest', () {
      final result = rows(
        [cardPurchase(50000, date: nov10), payCard(20000, date: nov20)],
        plans: plans,
        month: december,
      );
      expect(row(result, cardRow.id).carriedOver, php(30000));
    });

    test('Assigned on the card row does not carry over', () {
      final result = rows(
        const [],
        plans: [plan(cardRow.id, 100000)],
        month: december,
      );
      expect(row(result, cardRow.id).carriedOver, php(0));
      expect(row(result, cardRow.id).available, php(0));
    });

    test('a payment of old debt does not create carry over', () {
      final result = rows(
        [payCard(90000, date: nov10), cardPurchase(50000, date: nov20)],
        plans: plans,
        month: december,
      );
      // Paid before the purchase, but payments in a month use that month's
      // moved money: ₱500 moved, ₱900 paid, nothing left to carry.
      expect(row(result, cardRow.id).carriedOver, php(0));
    });

    test('a permanently deleted card row holds nothing back', () {
      const deleted = Category(
        id: '101',
        name: 'RCBC',
        kind: CategoryKind.spending,
        planGroup: PlanGroup.liability,
        linkedAccountId: rcbcCardId,
        isPlanArchived: true,
        isPlanDeleted: true,
      );
      final result = readyToAssign(
        month: december,
        budgetAccounts: [budget],
        plans: plans,
        transactions: [cardPurchase(50000, date: nov10)],
        categories: [categories[foodId]!, deleted],
        accounts: allAccounts,
      );
      expect(result.heldForCards, php(0));
    });
  });

  group('purchases that move nothing', () {
    test('without a category', () {
      final result = rows(
        [cardPurchase(50000, category: null)],
        plans: [plan(foodId, 500000)],
      );
      expect(row(result, cardRow.id).movedIn, php(0));
      expect(row(result, foodId).activity, php(0));
    });

    test('cash spending, cash advances and refunds to the card', () {
      final result = rows(
        [
          spending(amount: 10000),
          transfer(amount: 20000, from: rcbcCardId, to: bdoId),
          inflow(amount: 5000, to: rcbcCardId, category: foodId),
        ],
        plans: [plan(foodId, 500000)],
      );
      expect(row(result, cardRow.id).movedIn, php(0));
      expect(row(result, cardRow.id).activity, php(0));
    });

    test('loan rows are unchanged', () {
      final result = rows(
        [transfer(amount: 30000, to: carLoanId)],
        plans: [plan(loanRow.id, 30000)],
      );
      expect(row(result, loanRow.id).activity, php(30000));
      expect(row(result, loanRow.id).available, php(0));
    });
  });

  test('custom credit types are cards', () {
    final goldCard = Account(
      id: 'gold',
      name: 'Gold card',
      type: AccountType.credit,
      customTypeId: 'gold-type',
      openingBalance: php(0),
      createdAt: DateTime.utc(2026, 11, 1),
    );
    const goldRow = Category(
      id: '103',
      name: 'Gold card',
      kind: CategoryKind.spending,
      planGroup: PlanGroup.liability,
      linkedAccountId: 'gold',
    );
    final result = planSummaries(
      month: november,
      categories: [categories[foodId]!, goldRow],
      plans: [plan(foodId, 500000)],
      transactions: [cardPurchase(50000, card: 'gold')],
      accounts: [goldCard],
    );
    expect(row(result, goldRow.id).movedIn, php(50000));
  });

  test('spending totals and balances are unchanged', () {
    final transactions = [cardPurchase(50000), payCard(50000)];
    final totals = periodTotals(
      transactions,
      DateRange.monthOf(CalendarDate(2026, 11, 1)),
    );
    expect(totals.spending, php(50000));
    final balances = balancesFor(allAccounts, transactions);
    expect(balances[rcbcCardId], accounts[rcbcCardId]!.openingBalance);
    expect(balances[bdoId], php(1000000 - 50000));
  });

  test('editing or deleting a purchase recalculates every month', () {
    final plans = [plan(foodId, 500000)];
    final before = rows(
      [cardPurchase(50000, date: nov10)],
      plans: plans,
      month: december,
    );
    expect(row(before, cardRow.id).carriedOver, php(50000));
    final edited = rows(
      [cardPurchase(20000, date: nov10)],
      plans: plans,
      month: december,
    );
    expect(row(edited, cardRow.id).carriedOver, php(20000));
    final deleted = rows(const [], plans: plans, month: december);
    expect(row(deleted, cardRow.id).carriedOver, php(0));
  });

  test('cardRowFunding lists every card, with zeros when nothing moved', () {
    final funding = cardRowFunding(
      month: november,
      categories: allCategories,
      plans: const [],
      transactions: const [],
      accounts: allAccounts,
    );
    expect(funding.keys, [rcbcCardId]);
    expect(
      funding[rcbcCardId],
      CardRowFunding(carriedOver: php(0), movedIn: php(0)),
    );
  });
}
