import 'dart:convert';

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
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

Matcher throwsProblem(BackupImportProblem problem, [String detail = '']) =>
    throwsA(
      isA<BackupImportException>()
          .having((e) => e.problem, 'problem', problem)
          .having((e) => e.detail, 'detail', contains(detail)),
    );

void main() {
  // Each test uses two in-memory databases (source and target) on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime.utc(2026, 11, 17, 9);

  /// Fills [database] with one of everything, including archived records
  /// that hold history.
  Future<void> seed(AppDatabase database) async {
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
      planGroup: PlanGroup.liability,
    );
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
    // Archived records with history must restore too.
    await accounts.setArchived(gcash.id, archived: true);
    await categories.setArchived(gifts.id, archived: true);
    await accounts.setBudgetAccount(bdo.id);
  }

  late AppDatabase source;
  late AppDatabase target;

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    await seed(source);
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<String> exportJson(AppDatabase database) async =>
      (await BackupExporter(database, clock: () => now).createFile()).contents;

  Future<Map<String, Object?>> sourceBackup() async =>
      jsonDecode(await exportJson(source)) as Map<String, Object?>;

  test('export → restore → export gives the same backup', () async {
    // The target starts with different data, which must disappear.
    await AccountRepository(target).create(
      name: 'Will be replaced',
      type: AccountType.loan,
      enteredOpeningAmount: php(100),
    );
    final original = await exportJson(source);
    final importer = BackupImporter(target);

    await importer.replaceAll(importer.parse(original));

    expect(await exportJson(target), original);
  });

  test('a format 1 backup restores with every category in Spending', () async {
    final backup = await sourceBackup();
    backup['formatVersion'] = 1;
    (backup['categories']! as List).removeWhere(
      (c) => (c as Map)['linkedAccountId'] != null,
    );
    for (final category in backup['categories']! as List) {
      (category as Map<String, Object?>).remove('planGroup');
    }
    final importer = BackupImporter(target);

    await importer.replaceAll(importer.parse(jsonEncode(backup)));

    final restored = await target.select(target.categories).get();
    expect(
      restored
          .where((c) => c.linkedAccountId == null)
          .map((c) => c.planGroup)
          .toSet(),
      {PlanGroup.spending},
    );
    expect(
      restored.where((c) => c.linkedAccountId != null).single.planGroup,
      PlanGroup.liability,
    );
  });

  test('a format 2 backup restores with no budget account', () async {
    final backup = await sourceBackup();
    backup['formatVersion'] = 2;
    (backup['categories']! as List).removeWhere(
      (c) => (c as Map)['linkedAccountId'] != null,
    );
    for (final account in backup['accounts']! as List) {
      (account as Map<String, Object?>).remove('isBudgetAccount');
    }
    final importer = BackupImporter(target);

    await importer.replaceAll(importer.parse(jsonEncode(backup)));

    final restored = await target.select(target.accounts).get();
    expect(restored, hasLength(3));
    expect(restored.where((a) => a.isBudgetAccount), isEmpty);
  });

  test(
    'format 3 restore creates linked rows for existing liabilities',
    () async {
      final backup = await sourceBackup();
      backup['formatVersion'] = 3;
      final oldCategories = backup['categories']! as List;
      oldCategories.removeWhere((c) => (c as Map)['linkedAccountId'] != null);
      for (final category in oldCategories) {
        (category as Map).remove('linkedAccountId');
      }
      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(jsonEncode(backup)));
      final rows = await target.select(target.categories).get();
      final linked = rows.singleWhere((c) => c.linkedAccountId != null);
      expect(linked.name, 'RCBC Credit');
      expect(linked.planGroup, PlanGroup.liability);
      expect(
        (await target.select(target.monthlyPlans).get())
            .single
            .assignedAmountMinor,
        100000,
      );
    },
  );

  test(
    'linked liability rows and their plans survive export and restore',
    () async {
      final linked = (await source.select(source.categories).get()).singleWhere(
        (c) => c.linkedAccountId != null,
      );
      await PlanRepository(source, clock: () => now).save(
        month: CalendarMonth(2026, 11),
        categoryId: linked.id,
        target: php(50000),
        assigned: php(25000),
      );
      final original = await exportJson(source);
      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(original));
      expect(await exportJson(target), original);
      expect(
        await target.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  for (final (description, key, value) in [
    ('missing account', 'linkedAccountId', 999),
    ('asset account', 'linkedAccountId', 1),
    ('wrong group', 'planGroup', 'spending'),
    ('archive mismatch', 'isArchived', true),
    ('wrong kind', 'kind', 'inflow'),
  ]) {
    test(
      'restore rejects a linked row with $description without changing data',
      () async {
        final before = await exportJson(target);
        final backup = await sourceBackup();
        final linked = (backup['categories']! as List)
            .cast<Map<String, Object?>>()
            .singleWhere((c) => c['linkedAccountId'] != null);
        linked[key] = value;
        final importer = BackupImporter(target);
        await expectLater(
          Future<void>(
            () async => importer.replaceAll(importer.parse(jsonEncode(backup))),
          ),
          throwsProblem(BackupImportProblem.invalidData),
        );
        expect(await exportJson(target), before);
      },
    );
  }

  test('restore rejects two categories linked to one account', () async {
    final backup = await sourceBackup();
    final rows = (backup['categories']! as List).cast<Map<String, Object?>>();
    final linked = rows.singleWhere((c) => c['linkedAccountId'] != null);
    (backup['categories']! as List).add({
      ...linked,
      'id': 999,
      'name': 'Duplicate debt',
    });
    expect(
      () => parseBackup(jsonEncode(backup)),
      throwsProblem(BackupImportProblem.invalidData, 'linkedAccountId'),
    );
  });

  test('the budget account survives a round trip', () async {
    final importer = BackupImporter(target);

    await importer.replaceAll(importer.parse(await exportJson(source)));

    final restored = await target.select(target.accounts).get();
    expect(
      [
        for (final a in restored)
          if (a.isBudgetAccount) a.name,
      ],
      ['BDO Savings'],
    );
  });

  test('parse reports when the backup was made and what it holds', () async {
    final snapshot = BackupImporter(target).parse(await exportJson(source));

    expect(snapshot.exportedAt, now);
    expect(
      snapshot.counts,
      const BackupCounts(
        customAccountTypes: 1,
        accounts: 3,
        categories: 11,
        transactions: 2,
        monthlyPlans: 1,
      ),
    );
  });

  test('currentCounts counts what the database holds', () async {
    expect(
      await BackupImporter(source).currentCounts(),
      const BackupCounts(
        customAccountTypes: 1,
        accounts: 3,
        categories: 11,
        transactions: 2,
        monthlyPlans: 1,
      ),
    );
  });

  group('rejects without changing anything', () {
    late String before;

    setUp(() async => before = await exportJson(target));

    /// Parses [json] (or [contents]) and, if parsing passes, restores it.
    Future<void> restore({Map<String, Object?>? json, String? contents}) async {
      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(contents ?? jsonEncode(json)));
    }

    Future<void> expectUnchanged() async =>
        expect(await exportJson(target), before);

    /// Changes one record of [list] in the source backup.
    Future<Map<String, Object?>> withRecord(
      String list,
      int index,
      void Function(Map<String, Object?> record) change,
    ) async {
      final backup = await sourceBackup();
      change((backup[list]! as List)[index] as Map<String, Object?>);
      return backup;
    }

    test('text that is not JSON', () async {
      await expectLater(
        restore(contents: 'not json'),
        throwsProblem(BackupImportProblem.notABackup),
      );
      await expectUnchanged();
    });

    test('JSON that is not a Fundly backup', () async {
      await expectLater(
        restore(json: {'app': 'other'}),
        throwsProblem(BackupImportProblem.notABackup),
      );
      await expectLater(
        restore(contents: '[1, 2]'),
        throwsProblem(BackupImportProblem.notABackup),
      );
      await expectUnchanged();
    });

    test('a newer backup format', () async {
      final backup = await sourceBackup();
      backup['formatVersion'] = BackupExporter.formatVersion + 1;

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.newerFormat),
      );
      await expectUnchanged();
    });

    test('a missing field', () async {
      final backup = await withRecord('accounts', 0, (a) => a.remove('name'));

      await expectLater(
        restore(json: backup),
        throwsProblem(
          BackupImportProblem.invalidData,
          'accounts[0].name: missing',
        ),
      );
      await expectUnchanged();
    });

    test('a field of the wrong type', () async {
      final backup = await withRecord(
        'transactions',
        0,
        (t) => t['amountMinor'] = 500.25,
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(
          BackupImportProblem.invalidData,
          'transactions[0].amountMinor',
        ),
      );
      await expectUnchanged();
    });

    test('an unknown enum value', () async {
      final backup = await withRecord(
        'accounts',
        0,
        (a) => a['type'] = 'investment',
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'unknown value'),
      );
      await expectUnchanged();
    });

    test('a reference to a missing account', () async {
      final backup = await withRecord(
        'transactions',
        1,
        (t) => t['destinationAccountId'] = 99,
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(
          BackupImportProblem.invalidData,
          'destinationAccountNotFound',
        ),
      );
      await expectUnchanged();
    });

    test('an account whose custom type has another base type', () async {
      final backup = await withRecord('accounts', 2, (a) {
        // RCBC Credit (credit) pointed at E-wallet (savingsCash).
        a['customTypeId'] = 1;
      });

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'accounts[2]'),
      );
      await expectUnchanged();
    });

    test('a transaction that breaks a rule', () async {
      final backup = await withRecord('transactions', 1, (t) {
        // A transfer to the account it comes from (rule 7).
        t['destinationAccountId'] = t['sourceAccountId'];
      });

      await expectLater(
        restore(json: backup),
        throwsProblem(
          BackupImportProblem.invalidData,
          'sameSourceAndDestination',
        ),
      );
      await expectUnchanged();
    });

    test('a negative amount', () async {
      final backup = await withRecord(
        'transactions',
        0,
        (t) => t['amountMinor'] = -100,
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'amountNotPositive'),
      );
      await expectUnchanged();
    });

    test('an opening balance with the wrong sign', () async {
      final backup = await withRecord(
        'accounts',
        2,
        (a) => a['openingBalanceMinor'] = 300000,
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'wrong sign'),
      );
      await expectUnchanged();
    });

    test('duplicate IDs and names', () async {
      final duplicateId = await withRecord('categories', 1, (c) => c['id'] = 1);
      await expectLater(
        restore(json: duplicateId),
        throwsProblem(BackupImportProblem.invalidData, 'used twice'),
      );

      final duplicateName = await withRecord(
        'accounts',
        1,
        (a) => a['name'] = 'bdo savings',
      );
      await expectLater(
        restore(json: duplicateName),
        throwsProblem(BackupImportProblem.invalidData, 'used twice'),
      );
      await expectUnchanged();
    });

    test('a timestamp that is not UTC', () async {
      final backup = await withRecord(
        'accounts',
        0,
        (a) => a['createdAt'] = '2026-11-16T09:30:00.000',
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'UTC timestamp'),
      );
      await expectUnchanged();
    });

    test('another currency (G6)', () async {
      final backup = await withRecord(
        'accounts',
        0,
        (a) => a['currencyCode'] = 'USD',
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'only PHP'),
      );
      await expectUnchanged();
    });

    test('a format 2 category without a plan group', () async {
      final backup = await withRecord(
        'categories',
        0,
        (c) => c.remove('planGroup'),
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(
          BackupImportProblem.invalidData,
          'categories[0].planGroup: missing',
        ),
      );
      await expectUnchanged();
    });

    test('an inflow category with a plan group', () async {
      final backup = await withRecord(
        'categories',
        7, // Salary (inflow)
        (c) => c['planGroup'] = 'savings',
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'have no group'),
      );
      await expectUnchanged();
    });

    test('two budget accounts', () async {
      final backup = await withRecord(
        'accounts',
        1, // GCash, archived in the source; made active here
        (a) => a
          ..['isArchived'] = false
          ..['isBudgetAccount'] = true,
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'only one budget'),
      );
      await expectUnchanged();
    });

    test('a Credit or archived budget account', () async {
      final backup = await sourceBackup();
      final accounts = backup['accounts']! as List;
      (accounts[0] as Map<String, Object?>)['isBudgetAccount'] = false;
      (accounts[2] as Map<String, Object?>)['isBudgetAccount'] = true;

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'active Savings/Cash'),
      );

      (accounts[2] as Map<String, Object?>)['isBudgetAccount'] = false;
      // GCash is archived in the source.
      (accounts[1] as Map<String, Object?>)['isBudgetAccount'] = true;
      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'active Savings/Cash'),
      );
      await expectUnchanged();
    });

    test('a plan for an inflow category', () async {
      final backup = await withRecord(
        'monthlyPlans',
        0,
        (p) => p['categoryId'] = 8, // Salary (inflow)
      );

      await expectLater(
        restore(json: backup),
        throwsProblem(BackupImportProblem.invalidData, 'spending category'),
      );
      await expectUnchanged();
    });
  });
}
