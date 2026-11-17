import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
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
import 'package:fundly/features/plans/domain/plan_deletion.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/plans/domain/plan_validation_exception.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';

import '../../transactions/domain/transaction_fixtures.dart'
    show php, spending, cardPayment, transfer;

void main() {
  late AppDatabase database;
  late PlanRepository plans;
  late CategoryRepository categories;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late Account asset;
  late Account card;
  late Account loan;
  late int food;
  late int debt;
  late int loanPlan;
  final month = CalendarMonth(2026, 11);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    plans = PlanRepository(database, clock: () => DateTime(2026, 11, 17));
    categories = CategoryRepository(database);
    accounts = AccountRepository(database);
    transactions = TransactionRepository(database);
    asset = await accounts.create(
      name: 'Cash',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(100000),
    );
    card = await accounts.create(
      name: 'Card',
      type: AccountType.credit,
      enteredOpeningAmount: php(50000),
    );
    loan = await accounts.create(
      name: 'Loan',
      type: AccountType.loan,
      enteredOpeningAmount: php(50000),
    );
    final rows = await categories.watchAll().first;
    food = rows.singleWhere((c) => c.name == 'Food & Groceries').id;
    debt = rows.singleWhere((c) => c.linkedAccountId == card.id).id;
    loanPlan = rows.singleWhere((c) => c.linkedAccountId == loan.id).id;
  });
  tearDown(() => database.close());

  Future<PlanDeletionStatus> status(int id) =>
      plans.watchDeletionStatus(id).first;
  Future<Category> category(int id) async =>
      (await categories.watchAll().first).singleWhere((c) => c.id == id);
  Matcher blocked(PlanDeletionStatus value) => throwsA(
    isA<PlanDeletionException>().having((e) => e.status, 'status', value),
  );
  Future<void> save(int id, CalendarMonth at, int assigned) async {
    await plans.save(
      month: at,
      categoryId: id,
      target: php(20000),
      assigned: php(assigned),
    );
  }

  test(
    'deletes all zero-assigned targets while preserving category and accounts',
    () async {
      await save(food, month.previous, 0);
      await save(food, month, 0);
      await save(food, month.next, 0);
      await plans.setArchived(food, archived: true);
      final before = await accounts.watchAll().first;
      await plans.deletePermanently(food);
      final row = await category(food);
      expect(row.isArchived, isFalse);
      expect(row.isPlanArchived, isTrue);
      expect(row.isPlanDeleted, isTrue);
      expect(await accounts.watchAll().first, before);
      expect(await database.select(database.monthlyPlans).get(), isEmpty);
      expect(
        planSummaries(
          month: month,
          categories: [row],
          plans: [],
          transactions: [],
        ),
        isEmpty,
      );
      expect(
        planSummaries(
          month: month,
          categories: [row],
          plans: [],
          transactions: [],
          archived: true,
        ),
        isEmpty,
      );
    },
  );

  test(
    'active, missing, inflow and already-deleted rows are rejected',
    () async {
      await expectLater(
        plans.deletePermanently(food),
        blocked(PlanDeletionStatus.notArchived),
      );
      await expectLater(
        plans.deletePermanently(999),
        blocked(PlanDeletionStatus.categoryNotFound),
      );
      final salary = (await categories.watchAll().first).firstWhere(
        (c) => c.kind == CategoryKind.inflow,
      );
      await expectLater(
        plans.deletePermanently(salary.id),
        blocked(PlanDeletionStatus.categoryNotSpending),
      );
      await plans.setArchived(food, archived: true);
      await plans.deletePermanently(food);
      await expectLater(
        plans.deletePermanently(food),
        blocked(PlanDeletionStatus.alreadyDeleted),
      );
    },
  );

  for (final offset in [-1, 0, 1]) {
    test(
      'Assigned money in ${offset == -1
          ? 'past'
          : offset == 0
          ? 'current'
          : 'future'} months blocks deletion',
      () async {
        final at = offset == -1
            ? month.previous
            : offset == 0
            ? month
            : month.next;
        await save(food, at, 10000);
        // Parent category archive also places this row in Archived plans.
        await categories.setArchived(food, archived: true);
        expect(await status(food), PlanDeletionStatus.hasAssignedMoney);
        await expectLater(
          plans.deletePermanently(food),
          blocked(PlanDeletionStatus.hasAssignedMoney),
        );
        expect(
          (await plans.watchForMonth(at).first).single.assigned,
          php(10000),
        );
        expect((await category(food)).isPlanDeleted, isFalse);
      },
    );
  }

  for (final date in [
    CalendarDate(2026, 10, 1),
    CalendarDate(2026, 11, 17),
    CalendarDate(2027, 1, 1),
  ]) {
    test('spending on $date blocks permanent deletion', () async {
      await transactions.create(
        spending(from: asset.id, category: food, date: date),
      );
      await plans.setArchived(food, archived: true);
      await expectLater(
        plans.deletePermanently(food),
        blocked(PlanDeletionStatus.hasActivity),
      );
      expect((await category(food)).isPlanDeleted, isFalse);
    });
  }

  test(
    'credit-card payments and loan transfers block deletion of their debt row',
    () async {
      await transactions.create(cardPayment(from: asset.id, to: card.id));
      await transactions.create(transfer(from: asset.id, to: loan.id));
      for (final id in [debt, loanPlan]) {
        await plans.setArchived(id, archived: true);
        await expectLater(
          plans.deletePermanently(id),
          blocked(PlanDeletionStatus.hasActivity),
        );
      }
    },
  );

  test('unused debt plan deletion preserves account purchases and ordinary category', () async {
    final purchase = await transactions.create(
      spending(from: card.id, category: food),
    );
    await plans.setArchived(debt, archived: true);
    await plans.deletePermanently(debt);
    expect((await accounts.watchById(card.id).first)!.isArchived, isFalse);
    expect(await transactions.watchAll().first, [purchase]);
    expect((await category(food)).isPlanDeleted, isFalse);
    expect((await category(debt)).linkedAccountId, card.id);
  });

  test(
    'account rename/archive/unarchive never recreates a deleted debt row',
    () async {
      await plans.setArchived(debt, archived: true);
      await plans.deletePermanently(debt);
      await accounts.update(card.id, name: 'Renamed card');
      await accounts.setArchived(card.id, archived: true);
      await accounts.setArchived(card.id, archived: false);
      final row = await category(debt);
      expect(row.isPlanDeleted, isTrue);
      expect(row.name, 'Renamed card');
      expect(
        (await categories.watchAll().first).where(
          (c) => c.linkedAccountId == card.id,
        ),
        hasLength(1),
      );
      await expectLater(
        plans.setArchived(debt, archived: false),
        throwsA(
          isA<PlanValidationException>().having(
            (e) => e.error,
            'error',
            PlanValidationError.planDeleted,
          ),
        ),
      );
      await expectLater(
        save(debt, month, 0),
        throwsA(
          isA<PlanValidationException>().having(
            (e) => e.error,
            'error',
            PlanValidationError.planDeleted,
          ),
        ),
      );
    },
  );

  test(
    'eligibility reacts to changes and the write rejects stale permission',
    () async {
      final iterator = StreamIterator(plans.watchDeletionStatus(food));
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, PlanDeletionStatus.notArchived);
      await plans.setArchived(food, archived: true);
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, PlanDeletionStatus.allowed);
      await transactions.create(spending(from: asset.id, category: food));
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, PlanDeletionStatus.hasActivity);
      await expectLater(
        plans.deletePermanently(food),
        blocked(PlanDeletionStatus.hasActivity),
      );
      await iterator.cancel();
    },
  );

  test(
    'a failed flag update rolls back deletion of all monthly targets',
    () async {
      await save(food, month, 0);
      await plans.setArchived(food, archived: true);
      final before = await plans.watchForMonth(month).first;
      await database.customStatement(
        "CREATE TRIGGER fail_plan_delete BEFORE UPDATE OF is_plan_deleted ON categories WHEN NEW.is_plan_deleted = 1 BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
      );
      await expectLater(
        plans.deletePermanently(food),
        throwsA(isA<Exception>()),
      );
      expect(await plans.watchForMonth(month).first, before);
      expect((await category(food)).isPlanDeleted, isFalse);
    },
  );

  test('SQLite rejects deleted flags on active or inflow rows', () async {
    await expectLater(
      (database.update(database.categories)..where((c) => c.id.equals(food)))
          .write(const CategoriesCompanion(isPlanDeleted: Value(true))),
      throwsA(isA<Exception>()),
    );
    final salary = (await categories.watchAll().first).firstWhere(
      (c) => c.kind == CategoryKind.inflow,
    );
    await expectLater(
      (database.update(
        database.categories,
      )..where((c) => c.id.equals(salary.id))).write(
        const CategoriesCompanion(
          isPlanArchived: Value(true),
          isPlanDeleted: Value(true),
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
