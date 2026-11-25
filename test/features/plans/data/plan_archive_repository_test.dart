import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/plans/domain/plan_validation_exception.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';

import '../../transactions/domain/transaction_fixtures.dart'
    show php, spending, cardPayment, transfer;

void main() {
  late AppDatabase database;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late PlanRepository plans;
  late TransactionRepository transactions;
  late Account budget;
  late Account card;
  late String food;
  late String debt;
  final november = CalendarMonth(2026, 11);
  final december = CalendarMonth(2026, 12);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    accounts = AccountRepository(database);
    categories = CategoryRepository(database);
    transactions = TransactionRepository(database);
    plans = PlanRepository(database, clock: () => DateTime(2026, 11, 17));
    final asset = await accounts.create(
      name: 'Budget',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(100000),
    );
    budget = await accounts.setBudgetAccount(asset.id);
    card = await accounts.create(
      name: 'Card',
      type: AccountType.credit,
      enteredOpeningAmount: php(100000),
    );
    final all = await categories.watchAll().first;
    food = all.singleWhere((c) => c.name == 'Food & Groceries').id;
    debt = all.singleWhere((c) => c.linkedAccountId == card.id).id;
  });
  tearDown(() => database.close());

  Future<void> assign(
    String categoryId,
    int amount, {
    CalendarMonth? month,
  }) async {
    await plans.save(
      month: month ?? november,
      categoryId: categoryId,
      target: php(20000),
      assigned: php(amount),
    );
  }

  Future<Category> category(String id) async =>
      (await categories.watchAll().first).singleWhere((c) => c.id == id);
  Matcher blocked(Map<CalendarMonth, int> values) => throwsA(
    isA<PlanArchiveBlocked>().having(
      (e) => e.remainingByMonth.map(
        (key, value) => MapEntry(key, value.minorUnits),
      ),
      'remaining allocations',
      values,
    ),
  );

  test(
    'a zero-allocation row archives without archiving its category',
    () async {
      await assign(food, 0);
      final original = await plans.watchForMonth(november).first;
      await plans.setArchived(food, archived: true);
      final row = await category(food);
      expect(row.isPlanArchived, isTrue);
      expect(row.isArchived, isFalse);
      expect(await plans.watchForMonth(november).first, original);
      expect(
        (await categories.watchAll().first)
            .where((c) => c.isArchivedInPlans)
            .map((c) => c.id),
        [food],
      );
    },
  );

  test('a row with no saved monthly plan can be archived', () async {
    await plans.setArchived(food, archived: true);
    expect((await category(food)).isPlanArchived, isTrue);
    expect(await plans.watchForMonth(november).first, isEmpty);
  });

  test('loan transfers release only their own linked allocation', () async {
    final loan = await accounts.create(
      name: 'Loan',
      type: AccountType.loan,
      enteredOpeningAmount: php(10000),
    );
    final row = (await categories.watchAll().first).singleWhere(
      (c) => c.linkedAccountId == loan.id,
    );
    await assign(row.id, 10000);
    await transactions.create(
      transfer(from: budget.id, to: loan.id, amount: 10000),
    );
    await plans.setArchived(row.id, archived: true);
    expect((await category(row.id)).isPlanArchived, isTrue);
  });

  test('current and future remaining allocations block atomically', () async {
    await assign(food, 10000);
    await assign(food, 5000, month: december);
    await transactions.create(
      spending(from: budget.id, category: food, amount: 3000),
    );
    await expectLater(
      plans.setArchived(food, archived: true),
      blocked({november: 7000, december: 5000}),
    );
    expect((await category(food)).isPlanArchived, isFalse);
    expect(
      (await plans.watchForMonth(november).first).single.assigned,
      php(10000),
    );
  });

  test('historical assignments do not prevent archiving', () async {
    await assign(food, 10000, month: CalendarMonth(2026, 10));
    await plans.setArchived(food, archived: true);
    expect((await category(food)).isPlanArchived, isTrue);
    expect(
      (await plans.watchForMonth(CalendarMonth(2026, 10)).first)
          .single
          .assigned,
      php(10000),
    );
  });

  test('fully spent and overspent allocations allow archive', () async {
    await assign(food, 10000);
    await transactions.create(
      spending(from: budget.id, category: food, amount: 12000),
    );
    await plans.setArchived(food, archived: true);
    expect((await category(food)).isPlanArchived, isTrue);
    expect(
      (await plans.watchForMonth(november).first).single.assigned,
      php(10000),
    );
  });

  test('spending from another account does not release allocation', () async {
    await assign(food, 10000);
    await transactions.create(
      spending(from: card.id, category: food, amount: 10000),
    );
    await expectLater(
      plans.setArchived(food, archived: true),
      blocked({november: 10000}),
    );
  });

  test(
    'spending in another month does not release current allocation',
    () async {
      await assign(food, 10000);
      await transactions.create(
        spending(
          from: budget.id,
          category: food,
          amount: 10000,
          date: CalendarDate(2026, 10, 31),
        ),
      );
      await expectLater(
        plans.setArchived(food, archived: true),
        blocked({november: 10000}),
      );
    },
  );

  test(
    'without a budget account assigned money still blocks archive',
    () async {
      await assign(food, 10000);
      await transactions.create(
        spending(from: budget.id, category: food, amount: 10000),
      );
      await accounts.clearBudgetAccount(budget.id);
      await expectLater(
        plans.setArchived(food, archived: true),
        blocked({november: 10000}),
      );
    },
  );

  test(
    'spending from a second budget account releases the allocation',
    () async {
      final second = await accounts.create(
        name: 'Second budget',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(50000),
      );
      await accounts.setBudgetAccount(second.id);
      await assign(food, 10000);
      await transactions.create(
        spending(from: second.id, category: food, amount: 10000),
      );

      await plans.setArchived(food, archived: true);

      expect((await category(food)).isPlanArchived, isTrue);
    },
  );

  test('liability payments from budget release allocation without archiving account', () async {
    await assign(debt, 10000);
    await transactions.create(
      cardPayment(from: budget.id, to: card.id, amount: 10000),
    );
    await plans.setArchived(debt, archived: true);
    expect((await category(debt)).isPlanArchived, isTrue);
    expect((await accounts.watchById(card.id).first)!.isArchived, isFalse);
    await accounts.update(card.id, name: 'Renamed');
    await accounts.setArchived(card.id, archived: true);
    await accounts.setArchived(card.id, archived: false);
    expect((await category(debt)).isPlanArchived, isTrue);
  });

  test(
    'payments from another account do not release liability allocation',
    () async {
      final wallet = await accounts.create(
        name: 'Wallet',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(10000),
      );
      await assign(debt, 10000);
      await transactions.create(
        cardPayment(from: wallet.id, to: card.id, amount: 10000),
      );
      await expectLater(
        plans.setArchived(debt, archived: true),
        blocked({november: 10000}),
      );
    },
  );

  test('an archived row must be unarchived before assigning money', () async {
    await assign(food, 0);
    await plans.setArchived(food, archived: true);
    await expectLater(
      assign(food, 10000),
      throwsA(
        isA<PlanValidationException>().having(
          (e) => e.error,
          'error',
          PlanValidationError.planArchived,
        ),
      ),
    );
    await plans.setArchived(food, archived: false);
    await assign(food, 10000);
    expect((await category(food)).isPlanArchived, isFalse);
  });

  test('unarchive refuses a parent category that remains archived', () async {
    await plans.setArchived(food, archived: true);
    await categories.setArchived(food, archived: true);
    await expectLater(
      plans.setArchived(food, archived: false),
      throwsA(
        isA<PlanValidationException>().having(
          (e) => e.error,
          'error',
          PlanValidationError.categoryArchived,
        ),
      ),
    );
    await categories.setArchived(food, archived: false);
    await plans.setArchived(food, archived: false);
    expect((await category(food)).isArchivedInPlans, isFalse);
  });

  test('unknown and inflow categories cannot be archived as plans', () async {
    await expectLater(
      plans.setArchived('999', archived: true),
      throwsA(isA<PlanValidationException>()),
    );
    final salary = (await categories.watchAll().first).singleWhere(
      (c) => c.name == 'Salary',
    );
    await expectLater(
      plans.setArchived(salary.id, archived: true),
      throwsA(
        isA<PlanValidationException>().having(
          (e) => e.error,
          'error',
          PlanValidationError.categoryNotSpending,
        ),
      ),
    );
  });

  test(
    'later transaction edits do not silently release archived allocations',
    () async {
      await assign(food, 10000);
      final original = await transactions.create(
        spending(from: budget.id, category: food, amount: 10000),
      );
      await plans.setArchived(food, archived: true);
      await transactions.delete(original.id);
      final result = readyToAssign(
        accounts: await accounts.watchAll(includeArchived: true).first,
        month: november,
        budgetAccounts: [budget],
        plans: await plans.watchForMonth(november).first,
        categories: await categories.watchAll().first,
        transactions: await transactions.watchAll().first,
      );
      expect(result.assigned, php(10000));
      expect(result.amount, php(90000));
    },
  );
}
