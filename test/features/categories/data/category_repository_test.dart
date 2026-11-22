import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/data/default_categories.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/domain/category_validation_exception.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

void main() {
  late AppDatabase database;
  late CategoryRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepository(database);
  });

  tearDown(() => database.close());

  test(
    'a new database is seeded with the default categories in order',
    () async {
      final categories = await repository.watchAll().first;

      expect(
        categories.map((c) => (name: c.name, kind: c.kind)).toList(),
        defaultCategories,
      );
    },
  );

  test('filters spending categories in default order', () async {
    final names = (await repository.watchAll(kind: CategoryKind.spending).first)
        .map((c) => c.name);

    expect(
      names,
      defaultCategories
          .where((c) => c.kind == CategoryKind.spending)
          .map((c) => c.name),
    );
  });

  test('filters inflow categories', () async {
    final names = (await repository.watchAll(kind: CategoryKind.inflow).first)
        .map((c) => c.name);

    expect(names, ['Salary', 'Other income']);
  });

  group('database constraints', () {
    Future<void> insertRaw(String name, String kind) =>
        database.customStatement(
          'INSERT INTO categories (name, kind) VALUES (?, ?)',
          [name, kind],
        );

    test('rejects a duplicate name ignoring case', () {
      expect(
        insertRaw('food & groceries', 'spending'),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects an unknown kind', () {
      expect(insertRaw('Gifts', 'transfer'), throwsA(isA<Exception>()));
    });

    test('rejects empty and over-long names', () {
      expect(insertRaw('', 'spending'), throwsA(isA<Exception>()));
      expect(insertRaw('a' * 41, 'spending'), throwsA(isA<Exception>()));
    });

    test('rejects an unknown plan group', () {
      expect(
        database.customStatement(
          'INSERT INTO categories (name, kind, plan_group) '
          "VALUES ('Gifts', 'spending', 'investments')",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('accepts a valid new category', () async {
      await insertRaw('Gifts', 'spending');

      final names = (await repository.watchAll().first).map((c) => c.name);
      expect(names, contains('Gifts'));
    });
  });

  Matcher throwsCategoryError(CategoryValidationError error) => throwsA(
    isA<CategoryValidationException>().having((e) => e.error, 'error', error),
  );

  Future<Category> named(String name) async =>
      (await repository.watchAll().first).firstWhere((c) => c.name == name);

  group('create', () {
    test('adds a trimmed, active category after the seeded ones', () async {
      final created = await repository.create(
        name: '  Gifts ',
        kind: CategoryKind.spending,
      );

      expect(created.name, 'Gifts');
      expect(created.kind, CategoryKind.spending);
      expect(created.isArchived, isFalse);
      expect((await repository.watchAll().first).last, created);
    });

    test('rejects empty and over-long names', () async {
      await expectLater(
        repository.create(name: '   ', kind: CategoryKind.spending),
        throwsCategoryError(CategoryValidationError.nameEmpty),
      );
      await expectLater(
        repository.create(name: 'a' * 41, kind: CategoryKind.spending),
        throwsCategoryError(CategoryValidationError.nameTooLong),
      );
    });

    test('rejects a name used by either kind, ignoring case', () async {
      await expectLater(
        repository.create(name: 'SALARY', kind: CategoryKind.spending),
        throwsCategoryError(CategoryValidationError.nameTaken),
      );
    });

    test('rejects the name of an archived category', () async {
      final food = await named('Food & Groceries');
      await repository.setArchived(food.id, archived: true);

      await expectLater(
        repository.create(
          name: 'food & groceries',
          kind: CategoryKind.spending,
        ),
        throwsCategoryError(CategoryValidationError.nameTaken),
      );
    });
  });

  group('rename', () {
    test('changes the name and keeps the kind', () async {
      final salary = await named('Salary');

      final renamed = await repository.rename(salary.id, ' Wages ');

      expect(renamed.name, 'Wages');
      expect(renamed.kind, CategoryKind.inflow);
    });

    test('may change only the case of its own name', () async {
      final food = await named('Food & Groceries');

      expect(
        (await repository.rename(food.id, 'FOOD & GROCERIES')).name,
        'FOOD & GROCERIES',
      );
    });

    test('rejects a name used by another category', () async {
      final food = await named('Food & Groceries');

      await expectLater(
        repository.rename(food.id, 'fuel'),
        throwsCategoryError(CategoryValidationError.nameTaken),
      );
    });

    test('throws for an unknown id', () {
      expect(repository.rename('999', 'Gifts'), throwsStateError);
    });
  });

  group('plan groups', () {
    test('seeded categories start in the Spending group', () async {
      final categories = await repository.watchAll().first;

      expect(categories.map((c) => c.planGroup).toSet(), {PlanGroup.spending});
    });

    test('create puts a spending category in the chosen group', () async {
      final fund = await repository.create(
        name: 'Emergency fund',
        kind: CategoryKind.spending,
        planGroup: PlanGroup.savings,
      );

      expect(fund.planGroup, PlanGroup.savings);
      expect(await named('Emergency fund'), fund);
    });

    test('create defaults to the Spending group', () async {
      final gifts = await repository.create(
        name: 'Gifts',
        kind: CategoryKind.spending,
      );

      expect(gifts.planGroup, PlanGroup.spending);
    });

    test('an inflow category cannot get another group', () async {
      await expectLater(
        repository.create(
          name: 'Bonus',
          kind: CategoryKind.inflow,
          planGroup: PlanGroup.savings,
        ),
        throwsArgumentError,
      );
      expect(
        (await repository.watchAll().first).map((c) => c.name),
        isNot(contains('Bonus')),
      );
    });

    test('setPlanGroup moves a spending category, keeping the rest', () async {
      final food = await named('Food & Groceries');

      final moved = await repository.setPlanGroup(food.id, PlanGroup.liability);

      expect(moved.planGroup, PlanGroup.liability);
      expect(moved.name, 'Food & Groceries');
      expect(moved.kind, CategoryKind.spending);
      expect(await named('Food & Groceries'), moved);

      final back = await repository.setPlanGroup(food.id, PlanGroup.spending);
      expect(back.planGroup, PlanGroup.spending);
    });

    test('setPlanGroup works on an archived category', () async {
      final food = await named('Food & Groceries');
      await repository.setArchived(food.id, archived: true);

      final moved = await repository.setPlanGroup(food.id, PlanGroup.savings);

      expect(moved.planGroup, PlanGroup.savings);
      expect(moved.isArchived, isTrue);
    });

    test('setPlanGroup refuses an inflow category', () async {
      final salary = await named('Salary');

      await expectLater(
        repository.setPlanGroup(salary.id, PlanGroup.savings),
        throwsArgumentError,
      );
      expect((await named('Salary')).planGroup, PlanGroup.spending);
    });

    test('setPlanGroup throws for an unknown id', () {
      expect(
        repository.setPlanGroup('999', PlanGroup.savings),
        throwsStateError,
      );
    });
  });

  group('setArchived', () {
    test('archives and restores, keeping the category listed', () async {
      final food = await named('Food & Groceries');

      await repository.setArchived(food.id, archived: true);
      expect((await named('Food & Groceries')).isArchived, isTrue);

      await repository.setArchived(food.id, archived: false);
      expect((await named('Food & Groceries')).isArchived, isFalse);
    });

    test('throws for an unknown id', () {
      expect(repository.setArchived('999', archived: true), throwsStateError);
    });
  });

  group('delete', () {
    test('removes a category no transaction uses', () async {
      final gifts = await repository.create(
        name: 'Gifts',
        kind: CategoryKind.spending,
      );

      await repository.delete(gifts.id);

      expect(
        (await repository.watchAll().first).map((c) => c.id),
        isNot(contains(gifts.id)),
      );
    });

    test('rejects a category used by a transaction and keeps it', () async {
      final food = await named('Food & Groceries');
      final bdo = await AccountRepository(database).create(
        name: 'BDO Savings',
        type: AccountType.savingsCash,
        enteredOpeningAmount: const Money(minorUnits: 0, currencyCode: 'PHP'),
      );
      await TransactionRepository(database).create(
        TransactionDraft(
          type: TransactionType.spending,
          amount: const Money(minorUnits: 50000, currencyCode: 'PHP'),
          date: CalendarDate(2026, 11, 16),
          payee: 'SM Supermarket',
          categoryId: food.id,
          sourceAccountId: bdo.id,
        ),
      );

      await expectLater(
        repository.delete(food.id),
        throwsCategoryError(CategoryValidationError.inUse),
      );
      expect(await named('Food & Groceries'), food);
    });

    test('throws for an unknown id', () {
      expect(repository.delete('999'), throwsStateError);
    });
  });

  test('foreign keys are enabled', () async {
    final result = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();

    expect(result.read<int>('foreign_keys'), 1);
  });
}
