import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_validation_exception.dart';

void main() {
  late AppDatabase database;
  late PlanRepository repository;
  late CategoryRepository categories;
  late int food;
  late int transport;
  late int salary;
  var clockTime = DateTime.utc(2026, 11, 16, 9);

  final november = CalendarMonth(2026, 11);
  final december = CalendarMonth(2026, 12);

  Money php(int minorUnits) =>
      Money(minorUnits: minorUnits, currencyCode: 'PHP');

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    clockTime = DateTime.utc(2026, 11, 16, 9);
    repository = PlanRepository(database, clock: () => clockTime);
    categories = CategoryRepository(database);
    final all = await categories.watchAll().first;
    int idOf(String name) => all.firstWhere((c) => c.name == name).id;
    food = idOf('Food');
    transport = idOf('Transport');
    salary = idOf('Salary');
  });

  tearDown(() => database.close());

  Matcher throwsPlanError(PlanValidationError error) => throwsA(
    isA<PlanValidationException>().having((e) => e.error, 'error', error),
  );

  Future<MonthlyPlan> plan(
    int categoryId,
    int amount, {
    CalendarMonth? month,
  }) => repository.setPlannedAmount(
    month: month ?? november,
    categoryId: categoryId,
    amount: php(amount),
  );

  Future<List<MonthlyPlan>> plansFor(CalendarMonth month) =>
      repository.watchForMonth(month).first;

  group('setPlannedAmount', () {
    test('creates a plan with UTC timestamps', () async {
      final created = await plan(food, 500000);

      expect(created.month, november);
      expect(created.categoryId, food);
      expect(created.plannedAmount, php(500000));
      expect(created.createdAt, DateTime.utc(2026, 11, 16, 9));
      expect(created.updatedAt, created.createdAt);
      expect(await plansFor(november), [created]);
    });

    test(
      'a second call replaces the amount and bumps updatedAt only',
      () async {
        final created = await plan(food, 500000);
        clockTime = DateTime.utc(2026, 11, 17, 9);

        final updated = await plan(food, 650000);

        expect(updated.id, created.id);
        expect(updated.plannedAmount, php(650000));
        expect(updated.createdAt, created.createdAt);
        expect(updated.updatedAt, DateTime.utc(2026, 11, 17, 9));
        expect(await plansFor(november), [updated]);
      },
    );

    test('zero is a valid plan', () async {
      final created = await plan(food, 0);

      expect(created.plannedAmount, php(0));
      expect(await plansFor(november), hasLength(1));
    });

    test('rejects a negative amount', () async {
      await expectLater(
        plan(food, -1),
        throwsPlanError(PlanValidationError.amountNegative),
      );
      expect(await plansFor(november), isEmpty);
    });

    test('rejects an inflow category', () async {
      await expectLater(
        plan(salary, 100),
        throwsPlanError(PlanValidationError.categoryNotSpending),
      );
    });

    test('rejects an unknown category', () async {
      await expectLater(
        plan(999, 100),
        throwsPlanError(PlanValidationError.categoryNotFound),
      );
    });

    test('rejects a new plan for an archived category', () async {
      await categories.setArchived(food, archived: true);

      await expectLater(
        plan(food, 100),
        throwsPlanError(PlanValidationError.categoryArchived),
      );
    });

    test('an archived category keeps and may change its plan', () async {
      await plan(food, 100);
      await categories.setArchived(food, archived: true);

      final updated = await plan(food, 200);

      expect(updated.plannedAmount, php(200));
    });

    test('rejects a currency other than PHP', () {
      expect(
        repository.setPlannedAmount(
          month: november,
          categoryId: food,
          amount: const Money(minorUnits: 100, currencyCode: 'USD'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('months are independent', () {
    test('each month has its own plans and nothing carries over', () async {
      await plan(food, 500000);
      await plan(transport, 200000);
      await plan(food, 300000, month: december);

      expect(
        (await plansFor(november)).map((p) => (p.categoryId, p.plannedAmount)),
        [(food, php(500000)), (transport, php(200000))],
      );
      expect(
        (await plansFor(december)).map((p) => (p.categoryId, p.plannedAmount)),
        [(food, php(300000))],
      );
      expect(await plansFor(CalendarMonth(2027, 1)), isEmpty);
    });
  });

  group('clear', () {
    test('removes only that month and category', () async {
      await plan(food, 500000);
      await plan(transport, 200000);
      await plan(food, 300000, month: december);

      await repository.clear(month: november, categoryId: food);

      expect((await plansFor(november)).map((p) => p.categoryId), [transport]);
      expect(await plansFor(december), hasLength(1));
    });

    test('does nothing when there is no plan', () async {
      await repository.clear(month: november, categoryId: food);

      expect(await plansFor(november), isEmpty);
    });
  });

  test('deleting a category deletes its plans', () async {
    final gifts = await categories.create(
      name: 'Gifts',
      kind: CategoryKind.spending,
    );
    await plan(gifts.id, 100000);
    await plan(gifts.id, 100000, month: december);
    await plan(food, 500000);

    await categories.delete(gifts.id);

    expect((await plansFor(november)).map((p) => p.categoryId), [food]);
    expect(await plansFor(december), isEmpty);
  });

  test('emits again after set and clear', () async {
    final emissions = repository
        .watchForMonth(november)
        .map((plans) => plans.length);
    final expectation = expectLater(emissions, emitsInOrder([0, 1, 0]));

    await pumpEventQueue();
    await plan(food, 100);
    await pumpEventQueue();
    await repository.clear(month: november, categoryId: food);

    await expectation;
  });

  group('database constraints (backstop if Dart checks are bypassed)', () {
    Future<void> insertRaw({
      String month = '2026-11',
      int? categoryId,
      int amount = 100,
    }) => database.customStatement(
      'INSERT INTO monthly_plans (month, category_id, planned_amount_minor, '
      'currency_code, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        month,
        categoryId ?? food,
        amount,
        'PHP',
        '2026-11-16T09:00:00.000Z',
        '2026-11-16T09:00:00.000Z',
      ],
    );

    test('accepts a valid row', () async {
      await insertRaw();

      expect(await plansFor(november), hasLength(1));
    });

    test('rejects a second plan for the same category and month', () async {
      await insertRaw();

      expect(insertRaw(), throwsA(isA<Exception>()));
    });

    test('rejects a negative amount', () {
      expect(insertRaw(amount: -1), throwsA(isA<Exception>()));
    });

    test('rejects malformed months', () {
      for (final month in ['2026-13', '2026-00', '2026-1', 'Nov 2026']) {
        expect(
          insertRaw(month: month),
          throwsA(isA<Exception>()),
          reason: month,
        );
      }
    });

    test('rejects an unknown category (foreign key)', () {
      expect(insertRaw(categoryId: 999), throwsA(isA<Exception>()));
    });
  });
}
