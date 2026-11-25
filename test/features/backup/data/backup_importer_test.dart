import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/database/record_id.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/data/custom_bank_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/backup_source.dart';
import 'package:fundly/features/backup/data/dataset_request.dart';
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

/// [backup] (format 7) with every ID and reference as an integer again, and
/// format 6 in its header.
Map<String, Object?> asFormat6(Map<String, Object?> backup) {
  const idFields = {
    'id',
    'customTypeId',
    'linkedAccountId',
    'categoryId',
    'sourceAccountId',
    'destinationAccountId',
  };
  return {
    for (final MapEntry(:key, :value) in backup.entries)
      key: value is List<Object?>
          ? [
              for (final record in value.cast<Map<String, Object?>>())
                {
                  for (final MapEntry(key: field, value: v) in record.entries)
                    field: idFields.contains(field) && v is String
                        ? int.parse(v)
                        : v,
                },
            ]
          : value,
    'formatVersion': 6,
  };
}

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
    // Banks (format 9): a built-in bank, and a custom bank on an archived
    // account.
    final coop = await CustomBankRepository(
      database,
      clock: () => now,
    ).create('Town Coop');
    final accounts = AccountRepository(database, clock: () => now);
    final bdo = await accounts.create(
      name: 'BDO Savings',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(1500000),
      bankKey: 'bdo',
    );
    final gcash = await accounts.create(
      name: 'GCash',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(0),
      customTypeId: eWallet.id,
      customBankId: coop.id,
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
    // A default Target, on a seeded category (format 8).
    final rent = (await categories.watchAll().first).firstWhere(
      (c) => c.name == 'Rent',
    );
    await categories.setDefaultTarget(rent.id, php(1500000));
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

  /// The source exported (format 7, text IDs).
  Future<Map<String, Object?>> exportedBackup() async =>
      jsonDecode(await exportJson(source)) as Map<String, Object?>;

  /// The source as a format 6 backup: integer IDs, as older app versions
  /// wrote them. Tests of formats 1–6 start from this.
  Future<Map<String, Object?>> sourceBackup() async =>
      asFormat6(await exportedBackup());

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
        categoryId: recordIdOf(linked.id),
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

  group('banks (format 9)', () {
    List<Map<String, Object?>> accountsOf(Map<String, Object?> backup) =>
        (backup['accounts']! as List).cast<Map<String, Object?>>();
    Map<String, Object?> accountNamed(
      Map<String, Object?> backup,
      String name,
    ) => accountsOf(backup).singleWhere((a) => a['name'] == name);

    test('restores custom banks and every account\'s bank', () async {
      final importer = BackupImporter(target);
      final snapshot = importer.parse(await exportJson(source));
      expect(snapshot.counts.customBanks, 1);
      await importer.replaceAll(snapshot);

      final restored = {
        for (final account in await AccountRepository(
          target,
        ).watchAll(includeArchived: true).first)
          account.name: account.bank,
      };
      final coop = (await CustomBankRepository(target).watchAll().first).single;
      expect(coop.name, 'Town Coop');
      expect(restored['BDO Savings'], (bankKey: 'bdo', customBankId: null));
      expect(restored['GCash'], (bankKey: null, customBankId: coop.id));
      expect(restored['RCBC Credit'], (bankKey: null, customBankId: null));
      expect((await importer.currentCounts()).customBanks, 1);
    });

    test('a format 8 file restores with no banks', () async {
      final backup = await exportedBackup();
      backup['formatVersion'] = 8;
      backup.remove('customBanks');
      for (final account in accountsOf(backup)) {
        account
          ..remove('bankKey')
          ..remove('customBankId');
      }
      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(jsonEncode(backup)));

      expect(await CustomBankRepository(target).watchAll().first, isEmpty);
      for (final account in await AccountRepository(
        target,
      ).watchAll(includeArchived: true).first) {
        expect(account.bank, (bankKey: null, customBankId: null));
      }
    });

    test('a format 9 file states both bank fields, even as null', () async {
      for (final field in ['bankKey', 'customBankId']) {
        final backup = await exportedBackup();
        accountsOf(backup).first.remove(field);
        expect(
          () => parseBackup(jsonEncode(backup)),
          throwsProblem(BackupImportProblem.invalidData, field),
          reason: field,
        );
      }
      final backup = await exportedBackup()
        ..remove('customBanks');
      expect(
        () => parseBackup(jsonEncode(backup)),
        throwsProblem(BackupImportProblem.invalidData, 'customBanks'),
      );
    });

    for (final (description, change, detail) in [
      (
        'an unknown bank',
        (Map<String, Object?> b) =>
            accountNamed(b, 'BDO Savings')['bankKey'] = 'komo',
        'unknown bank',
      ),
      (
        'two banks',
        (Map<String, Object?> b) => accountNamed(b, 'GCash')['bankKey'] = 'bdo',
        'one bank',
      ),
      (
        'a missing custom bank',
        (Map<String, Object?> b) =>
            accountNamed(b, 'BDO Savings')['customBankId'] = 'not-there',
        'no such bank',
      ),
      (
        'a custom bank with a built-in name',
        (Map<String, Object?> b) =>
            (b['customBanks']! as List)
                    .cast<Map<String, Object?>>()
                    .single['name'] =
                'gcash',
        'built-in bank name',
      ),
      (
        'two custom banks with one name',
        (Map<String, Object?> b) => (b['customBanks']! as List).add({
          'id': 'second',
          'name': 'TOWN COOP',
          'createdAt': '2026-11-17T09:00:00.000Z',
        }),
        'used twice',
      ),
    ]) {
      test('rejects $description without changing anything', () async {
        final before = await exportJson(target);
        final backup = await exportedBackup();
        change(backup);
        final importer = BackupImporter(target);
        await expectLater(
          Future<void>(
            () async => importer.replaceAll(importer.parse(jsonEncode(backup))),
          ),
          throwsProblem(BackupImportProblem.invalidData, detail),
        );
        expect(await exportJson(target), before);
      });
    }
  });

  group('default Target (format 8)', () {
    List<Map<String, Object?>> categoriesOf(Map<String, Object?> backup) =>
        (backup['categories']! as List).cast<Map<String, Object?>>();

    Future<Category> restoredNamed(String name) async =>
        (await CategoryRepository(
          target,
        ).watchAll().first).singleWhere((c) => c.name == name);

    test('restores with the category', () async {
      final original = await exportJson(source);
      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(original));

      expect((await restoredNamed('Rent')).defaultTarget, php(1500000));
      expect((await restoredNamed('Utilities')).defaultTarget, isNull);
    });

    test('a format 7 file restores with no default Target', () async {
      final backup = await exportedBackup();
      backup['formatVersion'] = 7;
      for (final category in categoriesOf(backup)) {
        category.remove('defaultTargetMinor');
      }
      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(jsonEncode(backup)));

      expect((await restoredNamed('Rent')).defaultTarget, isNull);
    });

    test('a format 8 category must state it, even as null', () async {
      final backup = await exportedBackup();
      categoriesOf(backup).first.remove('defaultTargetMinor');

      expect(
        () => parseBackup(jsonEncode(backup)),
        throwsProblem(BackupImportProblem.invalidData, 'defaultTargetMinor'),
      );
    });

    for (final (description, pick, value) in [
      ('a negative one', 'Rent', -1),
      ('one on an inflow category', 'Salary', 100),
      ('one on a debt row', 'RCBC Credit', 100),
    ]) {
      test('rejects $description', () async {
        final backup = await exportedBackup();
        categoriesOf(backup)
                .singleWhere((c) => c['name'] == pick)['defaultTargetMinor'] =
            value;

        expect(
          () => parseBackup(jsonEncode(backup)),
          throwsProblem(BackupImportProblem.invalidData, 'defaultTargetMinor'),
        );
      });
    }
  });

  test(
    'a card purchase with no category round-trips (format 10, R.18)',
    () async {
      final card = (await source.select(source.accounts).get()).singleWhere(
        (a) => a.name == 'RCBC Credit',
      );
      await TransactionRepository(source, clock: () => now).create(
        TransactionDraft(
          type: TransactionType.spending,
          amount: php(10000),
          date: CalendarDate(2026, 11, 20),
          payee: '7/11',
          sourceAccountId: recordIdOf(card.id),
        ),
      );
      final original = await exportJson(source);
      final rows =
          (jsonDecode(original) as Map<String, Object?>)['transactions']!
              as List;
      expect(
        rows.where(
          (t) =>
              (t! as Map)['type'] == 'spending' &&
              (t as Map)['categoryId'] == null,
        ),
        hasLength(1),
      );

      final importer = BackupImporter(target);
      await importer.replaceAll(importer.parse(original));
      expect(await exportJson(target), original);
    },
  );

  test('restore still rejects a cash purchase with no category', () async {
    final backup = await sourceBackup();
    final rows = (backup['transactions']! as List).cast<Map<String, Object?>>();
    final bdo = ((backup['accounts']! as List).cast<Map<String, Object?>>())
        .singleWhere((a) => a['name'] == 'BDO Savings')['id'];
    rows.add({
      ...rows.first,
      'id': 999,
      'type': 'spending',
      'categoryId': null,
      'sourceAccountId': bdo,
      'destinationAccountId': null,
    });
    expect(
      () => parseBackup(jsonEncode(backup)),
      throwsProblem(BackupImportProblem.invalidData, 'categoryMissing'),
    );
  });

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

  test('plan archive flags survive a round trip independently of accounts and categories', () async {
    final rows = await source.select(source.categories).get();
    final normal = rows.first;
    final debt = rows.singleWhere((c) => c.linkedAccountId != null);
    final repository = PlanRepository(source, clock: () => now);
    await repository.setArchived(recordIdOf(normal.id), archived: true);
    await repository.setArchived(recordIdOf(debt.id), archived: true);
    final original = await exportJson(source);
    final importer = BackupImporter(target);
    await importer.replaceAll(importer.parse(original));
    expect(await exportJson(target), original);
    final archived = (await target.select(target.categories).get()).where(
      (c) => c.isPlanArchived,
    );
    expect(archived.map((c) => c.id).toSet(), {normal.id, debt.id});
    expect(archived.every((c) => !c.isArchived), isTrue);
    expect(
      (await target.select(target.accounts).get())
          .singleWhere((a) => a.id == debt.linkedAccountId)
          .isArchived,
      isFalse,
    );
  });

  test('format 4 restores with no independent plan archive flags', () async {
    final backup = await sourceBackup();
    backup['formatVersion'] = 4;
    for (final row in backup['categories']! as List) {
      (row as Map).remove('isPlanArchived');
    }
    final importer = BackupImporter(target);
    await importer.replaceAll(importer.parse(jsonEncode(backup)));
    final rows = await target.select(target.categories).get();
    expect(rows.every((c) => !c.isPlanArchived), isTrue);
    expect(rows.where((c) => c.linkedAccountId != null), hasLength(1));
  });

  for (final invalid in ['true', 1, null]) {
    test(
      'restore rejects invalid plan archive flag $invalid without changing data',
      () async {
        final before = await exportJson(target);
        final backup = await sourceBackup();
        ((backup['categories']! as List).first as Map)['isPlanArchived'] =
            invalid;
        expect(
          () => parseBackup(jsonEncode(backup)),
          throwsProblem(BackupImportProblem.invalidData, 'isPlanArchived'),
        );
        expect(await exportJson(target), before);
      },
    );
  }

  test('restore rejects a plan archive flag on an inflow category', () async {
    final backup = await sourceBackup();
    final row = (backup['categories']! as List)
        .cast<Map<String, Object?>>()
        .firstWhere((c) => c['kind'] == 'inflow');
    row['isPlanArchived'] = true;
    expect(
      () => parseBackup(jsonEncode(backup)),
      throwsProblem(BackupImportProblem.invalidData, 'isPlanArchived'),
    );
  });

  test('deleted ordinary and linked debt plans survive backup/restore without resurrection', () async {
    final rows = await source.select(source.categories).get();
    final normal = rows.first;
    final debt = rows.singleWhere((c) => c.linkedAccountId != null);
    final repository = PlanRepository(source, clock: () => now);
    for (final row in [normal, debt]) {
      await repository.setArchived(recordIdOf(row.id), archived: true);
      await repository.deletePermanently(recordIdOf(row.id));
    }
    // The ordinary category remains usable after removing its Plans row.
    await TransactionRepository(source, clock: () => now).create(
      TransactionDraft(
        type: TransactionType.spending,
        amount: php(1000),
        date: CalendarDate(2026, 11, 17),
        payee: 'Shop',
        categoryId: recordIdOf(normal.id),
        sourceAccountId: '1',
      ),
    );
    final original = await exportJson(source);
    final importer = BackupImporter(target);
    await importer.replaceAll(importer.parse(original));
    expect(await exportJson(target), original);
    final restored = await target.select(target.categories).get();
    expect(restored.where((c) => c.isPlanDeleted).map((c) => c.id).toSet(), {
      normal.id,
      debt.id,
    });
    expect((await target.select(target.accounts).get()).length, 3);
    await AccountRepository(target)
        .update(recordIdOf(debt.linkedAccountId!), name: 'Renamed card');
    expect(
      (await target.select(target.categories).get())
          .singleWhere((c) => c.id == debt.id)
          .isPlanDeleted,
      isTrue,
    );
  });

  test('format 5 restores archive flags with no deleted plan flags', () async {
    final normal = (await source.select(source.categories).get()).first;
    await PlanRepository(
      source,
      clock: () => now,
    ).setArchived(recordIdOf(normal.id), archived: true);
    final backup = await sourceBackup();
    backup['formatVersion'] = 5;
    for (final row in backup['categories']! as List) {
      (row as Map).remove('isPlanDeleted');
    }
    final importer = BackupImporter(target);
    await importer.replaceAll(importer.parse(jsonEncode(backup)));
    final rows = await target.select(target.categories).get();
    expect(rows.every((c) => !c.isPlanDeleted), isTrue);
    expect(rows.singleWhere((c) => c.id == normal.id).isPlanArchived, isTrue);
  });

  for (final invalid in ['true', 1, null]) {
    test('restore rejects invalid plan deletion flag $invalid', () async {
      final before = await exportJson(target);
      final backup = await sourceBackup();
      ((backup['categories']! as List).first as Map)['isPlanDeleted'] = invalid;
      expect(
        () => parseBackup(jsonEncode(backup)),
        throwsProblem(BackupImportProblem.invalidData, 'isPlanDeleted'),
      );
      expect(await exportJson(target), before);
    });
  }

  test('restore rejects a deleted plan that is not archived', () async {
    final backup = await sourceBackup();
    ((backup['categories']! as List).first as Map)['isPlanDeleted'] = true;
    expect(
      () => parseBackup(jsonEncode(backup)),
      throwsProblem(BackupImportProblem.invalidData, 'isPlanDeleted'),
    );
  });

  test('restore rejects saved monthly plans for a deleted row', () async {
    final backup = await sourceBackup();
    final normal = (backup['categories']! as List).first as Map;
    normal['isPlanArchived'] = true;
    normal['isPlanDeleted'] = true;
    ((backup['monthlyPlans']! as List).first as Map)['categoryId'] =
        normal['id'];
    expect(
      () => parseBackup(jsonEncode(backup)),
      throwsProblem(BackupImportProblem.invalidData, 'categoryId'),
    );
  });

  test('a cash advance (transfer from a credit account) restores', () async {
    final backup = await exportedBackup();
    final accounts = (backup['accounts']! as List).cast<Map<String, Object?>>();
    final card = accounts.singleWhere((a) => a['name'] == 'RCBC Credit');
    final transfer = (backup['transactions']! as List)
        .cast<Map<String, Object?>>()
        .singleWhere((t) => t['type'] == 'transfer');
    transfer['sourceAccountId'] = card['id'];
    final importer = BackupImporter(target);

    await importer.replaceAll(importer.parse(jsonEncode(backup)));

    final restored = await target.select(target.transactions).get();
    final advance = restored.singleWhere(
      (t) => t.type == TransactionType.transfer,
    );
    final cardRow = (await target.select(target.accounts).get()).singleWhere(
      (a) => a.name == 'RCBC Credit',
    );
    expect(advance.sourceAccountId, cardRow.id);
  });

  test('several budget accounts restore and survive a round trip', () async {
    final backup = await sourceBackup();
    final gcash = (backup['accounts']! as List)
        .cast<Map<String, Object?>>()
        .singleWhere((a) => a['name'] == 'GCash');
    gcash
      ..['isArchived'] = false
      ..['isBudgetAccount'] = true;
    final importer = BackupImporter(target);

    await importer.replaceAll(importer.parse(jsonEncode(backup)));

    final restored = await target.select(target.accounts).get();
    expect(
      [
        for (final a in restored)
          if (a.isBudgetAccount) a.name,
      ]..sort(),
      ['BDO Savings', 'GCash'],
    );
    final again = jsonDecode(await exportJson(target)) as Map<String, Object?>;
    expect(
      [
        for (final a
            in (again['accounts']! as List).cast<Map<String, Object?>>())
          if (a['isBudgetAccount'] == true) a['name'],
      ]..sort(),
      ['BDO Savings', 'GCash'],
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
        customBanks: 1,
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
        customBanks: 1,
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

  group('format 7 (text IDs, cloud sync S6.3)', () {
    /// [backup] with every ID and reference replaced by a UUID, the way a
    /// signed-in export writes them.
    Map<String, Object?> withUuids(Map<String, Object?> backup) {
      final uuids = <String, String>{};
      String uuid(String table, String id) => uuids.putIfAbsent(
        '$table:$id',
        () =>
            '00000000-0000-4000-8000-${uuids.length.toString().padLeft(12, '0')}',
      );
      const references = {
        'customTypeId': 'customAccountTypes',
        'customBankId': 'customBanks',
        'linkedAccountId': 'accounts',
        'categoryId': 'categories',
        'sourceAccountId': 'accounts',
        'destinationAccountId': 'accounts',
      };
      return {
        for (final MapEntry(:key, :value) in backup.entries)
          key: value is List<Object?>
              ? [
                  for (final record in value.cast<Map<String, Object?>>())
                    {
                      for (final MapEntry(key: field, value: v)
                          in record.entries)
                        field: switch ((field, v)) {
                          ('id', final String id) => uuid(key, id),
                          (_, final String id)
                              when references.containsKey(field) =>
                            uuid(references[field]!, id),
                          _ => v,
                        },
                    },
                ]
              : value,
      };
    }

    test(
      'a signed-out export is format 7 and restores to the same data',
      () async {
        final backup = await exportedBackup();
        expect(backup['formatVersion'], 10);
        expect(
          (backup['accounts']! as List).first,
          containsPair('id', isA<String>()),
        );

        final importer = BackupImporter(target);
        await importer.replaceAll(importer.parse(jsonEncode(backup)));
        expect(await exportJson(target), await exportJson(source));
      },
    );

    test('a signed-in export with UUIDs restores signed out', () async {
      final original = await exportedBackup();
      final importer = BackupImporter(target);
      final snapshot = importer.parse(jsonEncode(withUuids(original)));
      expect(snapshot.counts, await BackupImporter(source).currentCounts());

      await importer.replaceAll(snapshot);
      // Restored with local numbers 1, 2, 3… in file order; the records and
      // their references are the same as in the source.
      final restored =
          jsonDecode(await exportJson(target)) as Map<String, Object?>;
      String names(Map<String, Object?> backup) {
        final accounts = {
          for (final a
              in (backup['accounts']! as List).cast<Map<String, Object?>>())
            a['id']: a['name'],
        };
        return [
          for (final t
              in (backup['transactions']! as List).cast<Map<String, Object?>>())
            '${t['amountMinor']} ${accounts[t['sourceAccountId']]} '
                '${accounts[t['destinationAccountId']]}',
        ].join('; ');
      }

      expect(names(restored), names(original));
    });

    test('the parsed records are what the restore writes', () async {
      final importer = BackupImporter(target);
      final snapshot = importer.parse(await exportJson(source));
      await importer.replaceAll(snapshot);

      final records = snapshot.records;
      final identity = <String, Map<String, String>>{
        'custom_account_types': {
          for (final r in records.customAccountTypes) '${r.id}': '${r.id}',
        },
        'custom_banks': {
          for (final r in records.customBanks) '${r.id}': '${r.id}',
        },
        'accounts': {for (final r in records.accounts) '${r.id}': '${r.id}'},
        'categories': {
          for (final r in records.categories) '${r.id}': '${r.id}',
        },
        'transactions': {
          for (final r in records.transactions) '${r.id}': '${r.id}',
        },
        'monthly_plans': {
          for (final r in records.monthlyPlans) '${r.id}': '${r.id}',
        },
      };
      expect(
        firstDifference(
          records,
          await LocalBackupSource(target).read(),
          identity,
        ),
        isNull,
      );
    });

    test(
      'the records include the liability rows added for old formats',
      () async {
        final backup = await sourceBackup();
        backup['formatVersion'] = 3;
        for (final category
            in (backup['categories']! as List).cast<Map<String, Object?>>()) {
          category.remove('linkedAccountId');
          category.remove('isPlanArchived');
          category.remove('isPlanDeleted');
        }
        final records = BackupImporter(target)
            .parse(jsonEncode(backup))
            .records;
        final linked = records.categories.where(
          (c) => c.linkedAccountId != null,
        );
        expect(linked.map((c) => c.planGroup), everyElement('liability'));
        expect(linked, isNotEmpty);
      },
    );

    group('rejects', () {
      Matcher invalid(String detail) =>
          throwsProblem(BackupImportProblem.invalidData, detail);

      Future<Map<String, Object?>> changed(
        String list,
        int index,
        void Function(Map<String, Object?> record) change,
      ) async {
        final backup = await exportedBackup();
        change((backup[list]! as List)[index] as Map<String, Object?>);
        return backup;
      }

      BackupSnapshot parse(Map<String, Object?> backup) =>
          BackupImporter(target).parse(jsonEncode(backup));

      test('an ID used twice in one table', () async {
        final backup = await changed('accounts', 1, (a) => a['id'] = '1');
        expect(() => parse(backup), invalid('accounts[1].id: used twice'));
      });

      test('a number where text is expected', () async {
        final number = await changed('accounts', 0, (a) => a['id'] = 1);
        expect(() => parse(number), invalid('accounts[0].id: expected text'));
        final reference = await changed(
          'transactions',
          0,
          (t) => t['categoryId'] = 1,
        );
        expect(
          () => parse(reference),
          invalid('transactions[0].categoryId: expected text or null'),
        );
      });

      test('an empty or overlong ID', () async {
        final empty = await changed('categories', 0, (c) => c['id'] = '');
        expect(() => parse(empty), invalid('categories[0].id: must be 1-64'));
        final long = await changed('categories', 0, (c) => c['id'] = 'x' * 65);
        expect(() => parse(long), invalid('categories[0].id: must be 1-64'));
      });

      test('a reference to a record that is not in the file', () async {
        final plan = await changed(
          'monthlyPlans',
          0,
          (p) => p['categoryId'] = 'missing',
        );
        expect(() => parse(plan), invalid('no such category'));
        final account = await changed(
          'accounts',
          1,
          (a) => a['customTypeId'] = 'missing',
        );
        expect(() => parse(account), invalid('no such account type'));
      });

      test('the format 6 rules, reached through format 7', () async {
        final name = await changed('accounts', 0, (a) => a['name'] = '');
        expect(() => parse(name), invalid('accounts[0].name'));
      });
    });
  });
}
