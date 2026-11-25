import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/record_id.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  final november = CalendarMonth(2026, 11);
  const transportId = '11';
  const transport = Category(
    id: transportId,
    name: 'Transport',
    kind: CategoryKind.spending,
  );
  // foodId, transportId and salaryId are active; giftsId is archived.
  final allCategories = [
    categories[foodId]!,
    transport,
    categories[salaryId]!,
    categories[giftsId]!,
  ];

  var nextPlanId = 1;

  /// A plan with [target] (`null` for none) and [assigned], which defaults
  /// to the target, or zero without one.
  MonthlyPlan plan(
    String categoryId,
    int? target, {
    int? assigned,
    CalendarMonth? month,
  }) => MonthlyPlan(
    id: recordIdOf(nextPlanId++),
    month: month ?? november,
    categoryId: categoryId,
    target: target == null ? null : php(target),
    assigned: php(assigned ?? target ?? 0),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  List<CategoryPlanSummary> summarize({
    bool archived = false,
    List<MonthlyPlan> plans = const [],
    List<TransactionDraft> transactions = const [],
  }) => planSummaries(
    month: november,
    archived: archived,
    categories: allCategories,
    plans: plans,
    transactions: transactions,
    accounts: accounts.values,
  );

  CategoryPlanSummary rowFor(
    List<CategoryPlanSummary> rows,
    String categoryId,
  ) => rows.singleWhere((row) => row.category.id == categoryId);

  test('one row per active spending category, in the given order', () {
    final rows = summarize();

    expect(rows.map((row) => row.category.id), [foodId, transportId]);
    for (final row in rows) {
      expect(row.hasPlan, isFalse);
      expect(row.target, isNull);
      expect(row.assigned, php(0));
      expect(row.activity, php(0));
      expect(row.available, php(0));
      expect(row.status, isNull);
      expect(row.isOverspent, isFalse);
    }
  });

  test('available is assigned minus activity', () {
    final rows = summarize(
      plans: [plan(foodId, 500000, assigned: 250000)],
      transactions: [
        spending(amount: 120000),
        spending(amount: 30000, from: walletId),
      ],
    );

    final food = rowFor(rows, foodId);
    expect(food.hasPlan, isTrue);
    expect(food.target, php(500000));
    expect(food.assigned, php(250000));
    expect(food.activity, php(150000));
    expect(food.available, php(100000));
    expect(food.isOverspent, isFalse);
  });

  test('spending more than assigned gives a negative available', () {
    final food = rowFor(
      summarize(
        plans: [plan(foodId, 100000)],
        transactions: [spending(amount: 125000)],
      ),
      foodId,
    );

    expect(food.available, php(-25000));
    expect(food.isOverspent, isTrue);
  });

  test('spending with nothing assigned is overspent', () {
    final food = rowFor(
      summarize(transactions: [spending(amount: 80000)]),
      foodId,
    );

    expect(food.hasPlan, isFalse);
    expect(food.activity, php(80000));
    expect(food.available, php(-80000));
    expect(food.isOverspent, isTrue);
  });

  group('status', () {
    PlanStatus? statusOf(MonthlyPlan plan) =>
        rowFor(summarize(plans: [plan]), plan.categoryId).status;

    test('funded when assigned equals or exceeds the target', () {
      expect(statusOf(plan(foodId, 500000)), PlanStatus.funded);
      expect(
        statusOf(plan(foodId, 500000, assigned: 600000)),
        PlanStatus.funded,
      );
    });

    test('underfunded when assigned is below the target', () {
      expect(
        statusOf(plan(foodId, 500000, assigned: 499999)),
        PlanStatus.underfunded,
      );
      expect(
        statusOf(plan(foodId, 500000, assigned: 0)),
        PlanStatus.underfunded,
      );
    });

    test('a zero target is funded with nothing assigned', () {
      expect(statusOf(plan(foodId, 0)), PlanStatus.funded);
    });

    test('none without a target, even with money assigned', () {
      final food = rowFor(
        summarize(plans: [plan(foodId, null, assigned: 100000)]),
        foodId,
      );

      expect(food.hasPlan, isTrue);
      expect(food.target, isNull);
      expect(food.status, isNull);
      expect(food.available, php(100000));
    });

    test('spending within assigned does not change it', () {
      final food = rowFor(
        summarize(
          plans: [plan(foodId, 100000)],
          transactions: [spending(amount: 100000)],
        ),
        foodId,
      );

      expect(food.available, php(0));
      expect(food.status, PlanStatus.funded);
    });

    test('overspent replaces funded, which isFunded still reports', () {
      final food = rowFor(
        summarize(
          plans: [plan(foodId, 100000)],
          transactions: [spending(amount: 125000)],
        ),
        foodId,
      );

      expect(food.status, PlanStatus.overspent);
      expect(food.isFunded, isTrue);
    });

    test('overspent replaces underfunded', () {
      final food = rowFor(
        summarize(
          plans: [plan(foodId, 500000, assigned: 100000)],
          transactions: [spending(amount: 100001)],
        ),
        foodId,
      );

      expect(food.status, PlanStatus.overspent);
      expect(food.isFunded, isFalse);
    });

    test('overspent without a target', () {
      final assignedOnly = rowFor(
        summarize(
          plans: [plan(foodId, null, assigned: 100000)],
          transactions: [spending(amount: 150000)],
        ),
        foodId,
      );
      expect(assignedOnly.isFunded, isNull);
      expect(assignedOnly.status, PlanStatus.overspent);

      final noPlan = rowFor(
        summarize(transactions: [spending(amount: 80000)]),
        foodId,
      );
      expect(noPlan.hasPlan, isFalse);
      expect(noPlan.status, PlanStatus.overspent);
    });

    test('editing or deleting spending recalculates it', () {
      final plans = [plan(foodId, 100000)];
      expect(
        rowFor(
          summarize(plans: plans, transactions: [spending(amount: 150000)]),
          foodId,
        ).status,
        PlanStatus.overspent,
      );
      expect(
        rowFor(
          summarize(plans: plans, transactions: [spending(amount: 50000)]),
          foodId,
        ).status,
        PlanStatus.funded,
      );
      expect(rowFor(summarize(plans: plans), foodId).status, PlanStatus.funded);
    });
  });

  test('activity is per category', () {
    final rows = summarize(
      transactions: [
        spending(amount: 100000),
        spending(amount: 40000, category: transportId),
      ],
    );

    expect(rowFor(rows, foodId).activity, php(100000));
    expect(rowFor(rows, transportId).activity, php(40000));
  });

  group('Rule 5: only Spending counts toward activity', () {
    test('inflows, refunds, transfers and card payments are ignored', () {
      final rows = summarize(
        plans: [plan(foodId, 500000)],
        transactions: [
          spending(amount: 100000),
          inflow(amount: 20000),
          // A refund to the card, even if it carried a category.
          inflow(to: rcbcCardId, amount: 10000, category: foodId),
          // Defensive: these types never carry a category in valid data.
          transfer(category: foodId),
          cardPayment(),
        ],
      );

      expect(rowFor(rows, foodId).activity, php(100000));
    });

    test('a card purchase is category Activity; paying it is not', () {
      final rows = summarize(
        plans: [plan(foodId, 500000)],
        transactions: [
          spending(amount: 300000, from: rcbcCardId),
          cardPayment(amount: 300000),
          spending(amount: 20000),
        ],
      );

      // Both purchases; the payment is Activity on the card's own row.
      expect(rowFor(rows, foodId).activity, php(320000));
      expect(rowFor(rows, foodId).available, php(180000));
    });

    test('custom credit types count as cards in category Activity', () {
      final rows = planSummaries(
        month: november,
        categories: allCategories,
        plans: const [],
        transactions: [spending(amount: 300000, from: 'custom-card')],
        accounts: [
          Account(
            id: 'custom-card',
            name: 'Gold card',
            type: AccountType.credit,
            customTypeId: 'gold-card',
            openingBalance: php(0),
            createdAt: DateTime.utc(2026, 11, 1),
          ),
        ],
      );
      expect(rowFor(rows, foodId).activity, php(300000));
    });

    test('without the card in accounts, the purchase counts', () {
      final rows = planSummaries(
        month: november,
        categories: allCategories,
        plans: const [],
        transactions: [spending(amount: 300000, from: rcbcCardId)],
        accounts: const [],
      );
      expect(rowFor(rows, foodId).activity, php(300000));
    });
  });

  group('the month boundary', () {
    test('includes the first and last day, excludes days outside', () {
      final rows = summarize(
        transactions: [
          spending(amount: 1, date: CalendarDate(2026, 10, 31)),
          spending(amount: 10, date: CalendarDate(2026, 11, 1)),
          spending(amount: 100, date: CalendarDate(2026, 11, 30)),
          spending(amount: 1000, date: CalendarDate(2026, 12, 1)),
        ],
      );

      expect(rowFor(rows, foodId).activity, php(110));
    });

    test('plans for other months are ignored', () {
      final rows = summarize(
        plans: [
          plan(foodId, 999, month: CalendarMonth(2026, 10)),
          plan(foodId, 500000),
          plan(transportId, 999, month: CalendarMonth(2026, 12)),
        ],
      );

      expect(rowFor(rows, foodId).target, php(500000));
      expect(rowFor(rows, transportId).target, isNull);
    });
  });

  group('default Target', () {
    // Transport has a PHP 5,000 default Target; Food has none.
    final withDefault = [
      categories[foodId]!,
      Category(
        id: transportId,
        name: 'Transport',
        kind: CategoryKind.spending,
        defaultTarget: php(500000),
      ),
    ];

    List<CategoryPlanSummary> summarizeDefaults({
      List<MonthlyPlan> plans = const [],
      List<TransactionDraft> transactions = const [],
      CalendarMonth? month,
    }) => planSummaries(
      month: month ?? november,
      categories: withDefault,
      plans: plans,
      transactions: transactions,
      accounts: accounts.values,
    );

    test('a month without its own plan uses the default Target', () {
      final row = rowFor(summarizeDefaults(), transportId);

      expect(row.hasPlan, isFalse);
      expect(row.target, php(500000));
      expect(row.status, PlanStatus.underfunded);
      expect(rowFor(summarizeDefaults(), foodId).target, isNull);
    });

    test('every month without a plan uses it, past and future alike', () {
      for (final month in [CalendarMonth(2025, 1), CalendarMonth(2027, 6)]) {
        expect(
          rowFor(summarizeDefaults(month: month), transportId).target,
          php(500000),
        );
      }
    });

    test("a month's own Target overrides the default", () {
      final row = rowFor(
        summarizeDefaults(plans: [plan(transportId, 300000)]),
        transportId,
      );

      expect(row.target, php(300000));
      expect(row.status, PlanStatus.funded);
    });

    test('a plan with no Target keeps the month without one', () {
      final row = rowFor(
        summarizeDefaults(plans: [plan(transportId, null)]),
        transportId,
      );

      expect(row.hasPlan, isTrue);
      expect(row.target, isNull);
      expect(row.status, isNull);
    });

    test('a plan in another month does not stop the default', () {
      final row = rowFor(
        summarizeDefaults(
          plans: [plan(transportId, 100000, month: CalendarMonth(2026, 10))],
        ),
        transportId,
      );

      expect(row.target, php(500000));
    });

    test('assigned is not carried over: it starts at zero', () {
      final row = rowFor(
        summarizeDefaults(
          plans: [
            plan(
              transportId,
              500000,
              assigned: 500000,
              month: CalendarMonth(2026, 10),
            ),
          ],
          transactions: [spending(amount: 20000, category: transportId)],
        ),
        transportId,
      );

      expect(row.assigned, php(0));
      expect(row.activity, php(20000));
      expect(row.available, php(-20000));
      expect(row.status, PlanStatus.overspent);
    });
  });

  group('archived and inflow categories', () {
    test('inflow categories never get a row', () {
      final rows = summarize(transactions: [inflow(category: salaryId)]);

      expect(rows.map((row) => row.category.id), isNot(contains(salaryId)));
    });

    test('an archived category is hidden when it has no plan or spending', () {
      expect(
        summarize().map((row) => row.category.id),
        isNot(contains(giftsId)),
      );
    });

    test('an archived category with a plan is shown in the archive', () {
      final gifts = rowFor(
        summarize(archived: true, plans: [plan(giftsId, 200000)]),
        giftsId,
      );

      expect(gifts.target, php(200000));
    });

    test('archived category spending is available in the archive', () {
      final gifts = rowFor(
        summarize(
          archived: true,
          transactions: [spending(amount: 5000, category: giftsId)],
        ),
        giftsId,
      );

      expect(gifts.activity, php(5000));
    });

    test('archived spending outside the month does not show the row', () {
      final rows = summarize(
        transactions: [
          spending(category: giftsId, date: CalendarDate(2026, 10, 15)),
        ],
      );

      expect(rows.map((row) => row.category.id), isNot(contains(giftsId)));
    });
  });

  group('readyToAssign', () {
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

    ReadyToAssign ready({
      int opening = 1000000,
      int? walletOpening,
      CalendarMonth? month,
      List<MonthlyPlan> plans = const [],
      List<TransactionDraft> transactions = const [],
    }) => readyToAssign(
      accounts: accounts.values,
      month: month ?? november,
      budgetAccounts: [
        Account(
          id: bdoId,
          name: 'Budget',
          type: accounts[bdoId]!.type,
          openingBalance: php(opening),
          createdAt: DateTime.utc(2026, 11, 1),
        ),
        // A second budget account, when given an opening balance.
        if (walletOpening != null)
          accounts[walletId]!.copyWith(openingBalance: php(walletOpening)),
      ],
      plans: plans,
      transactions: transactions,
      categories: [...allCategories, cardRow, loanRow],
    );

    TransactionDraft dated(
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
      categoryId: switch (type) {
        TransactionType.spending => foodId,
        TransactionType.inflow => salaryId,
        _ => null,
      },
    );

    test('carry over plus money in minus assigned', () {
      // ₱10,000 carried over, ₱30,000 salary, ₱25,000 assigned and ₱8,000
      // spent within plan leave ₱15,000, as the old live-balance rule did.
      final result = ready(
        plans: [plan(foodId, 1000000), plan(transportId, 1500000)],
        transactions: [inflow(amount: 3000000), spending(amount: 800000)],
      );
      expect(result.carryOver, php(1000000));
      expect(result.moneyIn, php(3000000));
      expect(result.movedOut, php(0));
      expect(result.assigned, php(2500000));
      expect(result.amount, php(1500000));
    });

    test('assigned includes archived categories', () {
      final result = ready(
        plans: [plan(foodId, 400000), plan(giftsId, null, assigned: 100000)],
      );
      expect(result.assigned, php(500000));
      expect(result.amount, php(500000));
    });

    test('overspending a category leaves it unchanged', () {
      final plans = [plan(foodId, 100000), plan(transportId, 200000)];
      expect(ready(plans: plans).amount, php(700000));
      expect(
        ready(plans: plans, transactions: [spending(amount: 300000)]).amount,
        php(700000),
      );
    });

    test('spending with nothing assigned leaves it unchanged', () {
      final result = ready(
        plans: [plan(transportId, 200000)],
        transactions: [spending(amount: 100000)],
      );
      expect(result.amount, php(800000));
    });

    test('spending from other accounts and card purchases are ignored', () {
      final result = ready(
        plans: [plan(foodId, 400000)],
        transactions: [
          spending(amount: 100000, from: walletId),
          spending(amount: 100000, from: rcbcCardId),
        ],
      );
      expect(result.moneyIn, php(0));
      expect(result.movedOut, php(0));
      expect(result.amount, php(600000));
    });

    test('a transfer into the budget account is money in', () {
      final result = ready(
        transactions: [transfer(amount: 100000, from: walletId, to: bdoId)],
      );
      expect(result.moneyIn, php(100000));
      expect(result.amount, php(1100000));
    });

    test('a cash advance into the budget account is money in', () {
      final result = ready(
        plans: [plan(cardRow.id, null, assigned: 50000)],
        transactions: [transfer(amount: 260000, from: rcbcCardId, to: bdoId)],
      );
      expect(result.moneyIn, php(260000));
      expect(result.amount, php(1210000));
    });

    test('a transfer out to a Savings/Cash account is moved out', () {
      final result = ready(transactions: [transfer(amount: 100000)]);
      expect(result.movedOut, php(100000));
      expect(result.amount, php(900000));
    });

    test('card and loan payments are debt-row Activity, not moved out', () {
      final result = ready(
        plans: [plan(cardRow.id, null, assigned: 100000)],
        transactions: [
          cardPayment(amount: 200000),
          transfer(amount: 300000, to: carLoanId),
        ],
      );
      expect(result.movedOut, php(0));
      expect(result.amount, php(900000));
    });

    test('inflows to other accounts are not money in', () {
      final result = ready(
        transactions: [
          inflow(amount: 900000, to: walletId),
          cardPayment(amount: 100000, from: walletId),
        ],
      );
      expect(result.moneyIn, php(0));
      expect(result.amount, php(1000000));
    });

    test('each month has its own money in, moved out and assigned', () {
      final transactions = [
        dated(
          TransactionType.inflow,
          500000,
          CalendarDate(2026, 10, 31),
          to: bdoId,
        ),
        dated(
          TransactionType.spending,
          100000,
          CalendarDate(2026, 10, 31),
          from: bdoId,
        ),
        dated(
          TransactionType.inflow,
          3000000,
          CalendarDate(2026, 11, 1),
          to: bdoId,
        ),
        dated(
          TransactionType.transfer,
          200000,
          CalendarDate(2026, 11, 30),
          from: bdoId,
          to: walletId,
        ),
        dated(
          TransactionType.inflow,
          700000,
          CalendarDate(2026, 12, 1),
          to: bdoId,
        ),
      ];
      final plans = [
        plan(foodId, 400000),
        plan(transportId, 900000, month: CalendarMonth(2026, 10)),
      ];

      final october = ready(
        month: CalendarMonth(2026, 10),
        plans: plans,
        transactions: transactions,
      );
      expect(october.carryOver, php(1000000));
      expect(october.moneyIn, php(500000));
      expect(october.assigned, php(900000));
      expect(october.amount, php(600000));

      final current = ready(plans: plans, transactions: transactions);
      expect(current.carryOver, php(1400000));
      expect(current.moneyIn, php(3000000));
      expect(current.movedOut, php(200000));
      expect(current.assigned, php(400000));
      expect(current.amount, php(3800000));

      final december = ready(
        month: CalendarMonth(2026, 12),
        plans: plans,
        transactions: transactions,
      );
      expect(december.carryOver, php(4200000));
      expect(december.moneyIn, php(700000));
      expect(december.assigned, php(0));
      expect(december.amount, php(4900000));
    });

    test('last month\'s spending reduces this month through carry over', () {
      final result = ready(
        transactions: [
          dated(
            TransactionType.spending,
            300000,
            CalendarDate(2026, 10, 31),
            from: bdoId,
          ),
        ],
      );
      expect(result.carryOver, php(700000));
      expect(result.amount, php(700000));
    });

    test('overallocated amounts are negative', () {
      expect(ready(plans: [plan(foodId, 1200000)]).amount, php(-200000));
      expect(
        ready(transactions: [transfer(amount: 1200000)]).amount,
        php(-200000),
      );
    });

    group('several budget accounts', () {
      test('carry over adds up every budget account', () {
        final result = ready(
          walletOpening: 200000,
          transactions: [
            dated(
              TransactionType.spending,
              50000,
              CalendarDate(2026, 10, 31),
              from: walletId,
            ),
          ],
        );
        expect(result.carryOver, php(1150000));
        expect(result.amount, php(1150000));
      });

      test('transfers between budget accounts are neither in nor out', () {
        final result = ready(
          walletOpening: 0,
          plans: [plan(foodId, 100000)],
          transactions: [
            transfer(amount: 100000, from: bdoId, to: walletId),
            transfer(amount: 30000, from: walletId, to: bdoId),
            // The money is then spent from the second budget account.
            spending(amount: 100000, from: walletId),
          ],
        );
        expect(result.moneyIn, php(0));
        expect(result.movedOut, php(0));
        expect(result.amount, php(900000));
      });

      test('inflows into any budget account are money in', () {
        final result = ready(
          walletOpening: 0,
          transactions: [
            inflow(amount: 100000),
            inflow(amount: 50000, to: walletId),
          ],
        );
        expect(result.moneyIn, php(150000));
      });

      test('a transfer to a non-budget account is still moved out', () {
        final result = ready(
          transactions: [transfer(amount: 100000, from: bdoId, to: walletId)],
        );
        expect(result.movedOut, php(100000));
      });
    });

    test('zero with no money or assignments', () {
      expect(ready(opening: 0).amount, php(0));
    });

    test('editing or deleting a transaction recalculates it', () {
      final plans = [plan(foodId, 400000)];
      expect(
        ready(plans: plans, transactions: [inflow(amount: 100000)]).amount,
        php(700000),
      );
      expect(
        ready(plans: plans, transactions: [inflow(amount: 200000)]).amount,
        php(800000),
      );
      expect(
        ready(plans: plans, transactions: [transfer(amount: 100000)]).amount,
        php(500000),
      );
      expect(ready(plans: plans).amount, php(600000));
    });
  });
}
