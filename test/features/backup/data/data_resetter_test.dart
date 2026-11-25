import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/data_resetter.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/data/default_categories.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  // One test compares with a second, freshly installed database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime.utc(2026, 11, 22, 9);
  late AppDatabase database;

  /// One of everything: a custom type, archived records with history, a
  /// renamed default, a plan, a linked debt row and a budget account.
  Future<void> seed() async {
    final eWallet = await CustomAccountTypeRepository(
      database,
      clock: () => now,
    ).create(name: 'E-wallet', baseType: AccountType.savingsCash);
    final accounts = AccountRepository(database, clock: () => now);
    final bdo = await accounts.create(
      name: 'BDO Savings',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(1500000),
    );
    final gcash = await accounts.create(
      name: 'GCash',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(0),
      customTypeId: eWallet.id,
    );
    final card = await accounts.create(
      name: 'RCBC Credit',
      type: AccountType.credit,
      enteredOpeningAmount: php(300000),
    );
    final categories = CategoryRepository(database);
    final gifts = await categories.create(
      name: 'Gifts',
      kind: CategoryKind.spending,
    );
    final rent = (await categories.watchAll().first).firstWhere(
      (category) => category.name == 'Rent',
    );
    await categories.rename(rent.id, 'Housing');
    final transactions = TransactionRepository(database, clock: () => now);
    await transactions.create(
      TransactionDraft(
        type: TransactionType.spending,
        amount: php(50025),
        date: CalendarDate(2026, 11, 10),
        payee: 'SM Supermarket',
        categoryId: gifts.id,
        sourceAccountId: card.id,
      ),
    );
    await transactions.create(
      TransactionDraft(
        type: TransactionType.transfer,
        amount: php(200000),
        date: CalendarDate(2026, 11, 11),
        sourceAccountId: bdo.id,
        destinationAccountId: gcash.id,
      ),
    );
    await PlanRepository(database, clock: () => now).save(
      month: CalendarMonth(2026, 11),
      categoryId: gifts.id,
      target: null,
      assigned: php(100000),
    );
    await accounts.setArchived(gcash.id, archived: true);
    await categories.setArchived(gifts.id, archived: true);
    await accounts.setBudgetAccount(bdo.id);
  }

  Future<BackupCounts> counts() => BackupImporter(database).currentCounts();

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await seed();
  });

  tearDown(() => database.close());

  test('deletes every record and brings back the default categories', () async {
    await DataResetter(database).resetAll();

    expect(
      await counts(),
      BackupCounts(
        customAccountTypes: 0,
        accounts: 0,
        categories: defaultCategories.length,
        transactions: 0,
        monthlyPlans: 0,
        customBanks: 0,
      ),
    );
    final categories = await CategoryRepository(database).watchAll().first;
    expect([
      for (final category in categories)
        (name: category.name, kind: category.kind),
    ], defaultCategories);
    for (final category in categories) {
      expect(category.isArchived, isFalse);
      expect(category.isPlanArchived, isFalse);
      expect(category.isPlanDeleted, isFalse);
      expect(category.linkedAccountId, isNull);
      expect(category.planGroup, PlanGroup.spending);
    }
  });

  test('leaves the same data as a fresh install', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    await DataResetter(database).resetAll();

    final reset = await CategoryRepository(database).watchAll().first;
    final installed = await CategoryRepository(fresh).watchAll().first;
    expect(
      [for (final c in reset) (c.name, c.kind, c.planGroup)],
      [for (final c in installed) (c.name, c.kind, c.planGroup)],
    );
    expect(await counts(), await BackupImporter(fresh).currentCounts());
  });

  test(
    'archived accounts are gone too, so their names can be reused',
    () async {
      await DataResetter(database).resetAll();

      final accounts = AccountRepository(database, clock: () => now);
      expect(await accounts.watchAll(includeArchived: true).first, isEmpty);
      final gcash = await accounts.create(
        name: 'GCash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(0),
      );
      // A new account can become the budget account: the old one is gone.
      final budget = await accounts.setBudgetAccount(gcash.id);
      expect(budget.isBudgetAccount, isTrue);
    },
  );

  test('a failure part way through changes nothing', () async {
    final before = await counts();
    // Make the final step (adding the default categories) fail.
    await database.customStatement(
      'CREATE TRIGGER block_categories BEFORE INSERT ON categories '
      "BEGIN SELECT RAISE(ABORT, 'blocked'); END",
    );

    await expectLater(DataResetter(database).resetAll(), throwsA(anything));

    expect(await counts(), before);
    expect(
      (await AccountRepository(database).watchAll().first).map((a) => a.name),
      ['BDO Savings', 'RCBC Credit'],
    );
  });

  test('resetting an already empty database works', () async {
    await DataResetter(database).resetAll();
    await DataResetter(database).resetAll();

    expect((await counts()).categories, defaultCategories.length);
  });
}
