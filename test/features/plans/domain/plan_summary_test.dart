import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';

import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  final november = CalendarMonth(2026, 11);
  const transportId = 11;
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
    int categoryId,
    int? target, {
    int? assigned,
    CalendarMonth? month,
  }) => MonthlyPlan(
    id: nextPlanId++,
    month: month ?? november,
    categoryId: categoryId,
    target: target == null ? null : php(target),
    assigned: php(assigned ?? target ?? 0),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  List<CategoryPlanSummary> summarize({
    List<MonthlyPlan> plans = const [],
    List<TransactionDraft> transactions = const [],
  }) => planSummaries(
    month: november,
    categories: allCategories,
    plans: plans,
    transactions: transactions,
  );

  CategoryPlanSummary rowFor(List<CategoryPlanSummary> rows, int categoryId) =>
      rows.singleWhere((row) => row.category.id == categoryId);

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
        spending(amount: 30000, from: rcbcCardId),
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

    test('spending does not change it; overspending shows in available', () {
      final food = rowFor(
        summarize(
          plans: [plan(foodId, 100000)],
          transactions: [spending(amount: 125000)],
        ),
        foodId,
      );

      expect(food.status, PlanStatus.funded);
      expect(food.isOverspent, isTrue);
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

    test('Rule 6: a card purchase counts once; paying the card adds none', () {
      final rows = summarize(
        transactions: [
          spending(amount: 300000, from: rcbcCardId),
          cardPayment(amount: 300000),
        ],
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

    test('an archived category with a plan this month is shown', () {
      final gifts = rowFor(summarize(plans: [plan(giftsId, 200000)]), giftsId);

      expect(gifts.target, php(200000));
    });

    test('an archived category with spending this month is shown', () {
      final gifts = rowFor(
        summarize(transactions: [spending(amount: 5000, category: giftsId)]),
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
}
