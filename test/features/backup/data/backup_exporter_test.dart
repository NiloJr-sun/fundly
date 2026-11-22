import 'dart:convert';

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
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  late AppDatabase database;
  final createdAt = DateTime.utc(2026, 11, 16, 9, 30);
  final exportedAt = DateTime.utc(2026, 11, 17, 1, 2, 3);

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  BackupExporter exporter() =>
      BackupExporter(database, clock: () => exportedAt);

  test(
    'an empty database still has the header and seeded categories',
    () async {
      final backup = await exporter().export();

      expect(backup['app'], 'fundly');
      expect(backup['formatVersion'], 6);
      expect(backup['schemaVersion'], database.schemaVersion);
      expect(backup['exportedAt'], '2026-11-17T01:02:03.000Z');
      expect(backup['customAccountTypes'], isEmpty);
      expect(backup['accounts'], isEmpty);
      expect(backup['transactions'], isEmpty);
      expect(backup['monthlyPlans'], isEmpty);
      expect(backup['categories'], hasLength(9));
      expect((backup['categories']! as List).first, {
        'id': 1,
        'name': 'Rent',
        'kind': 'spending',
        'isArchived': false,
        'planGroup': 'spending',
        'isPlanArchived': false,
        'isPlanDeleted': false,
        'linkedAccountId': null,
      });
    },
  );

  test('exports every record with its references, in id order', () async {
    final eWallet = await CustomAccountTypeRepository(
      database,
      clock: () => createdAt,
    ).create(name: 'E-wallet', baseType: AccountType.savingsCash);
    final accounts = AccountRepository(database, clock: () => createdAt);
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
    final gifts = await CategoryRepository(database).create(
      name: 'Gifts',
      kind: CategoryKind.spending,
      planGroup: PlanGroup.savings,
    );
    final transactions = TransactionRepository(
      database,
      clock: () => createdAt,
    );
    await transactions.create(
      TransactionDraft(
        type: TransactionType.spending,
        amount: php(50025),
        date: CalendarDate(2026, 11, 10),
        payee: 'SM Supermarket',
        categoryId: gifts.id,
        sourceAccountId: card.id,
        note: 'Birthday',
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
    await accounts.setArchived(gcash.id, archived: true);
    await accounts.setBudgetAccount(bdo.id);
    await PlanRepository(database, clock: () => createdAt).save(
      month: CalendarMonth(2026, 11),
      categoryId: gifts.id,
      target: null,
      assigned: php(100000),
    );

    final backup = await exporter().export();

    expect(backup['customAccountTypes'], [
      {
        'id': int.parse(eWallet.id),
        'name': 'E-wallet',
        'baseType': 'savingsCash',
        'createdAt': '2026-11-16T09:30:00.000Z',
      },
    ]);
    expect(backup['accounts'], [
      {
        'id': int.parse(bdo.id),
        'name': 'BDO Savings',
        'type': 'savingsCash',
        'customTypeId': null,
        'openingBalanceMinor': 1500000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'isArchived': false,
        'isBudgetAccount': true,
      },
      {
        'id': int.parse(gcash.id),
        'name': 'GCash',
        'type': 'savingsCash',
        'customTypeId': int.parse(eWallet.id),
        'openingBalanceMinor': 0,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'isArchived': true,
        'isBudgetAccount': false,
      },
      {
        'id': int.parse(card.id),
        'name': 'RCBC Credit',
        'type': 'credit',
        'customTypeId': null,
        // Signed as stored (D1): money owed is negative.
        'openingBalanceMinor': -300000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'isArchived': false,
        'isBudgetAccount': false,
      },
    ]);
    expect((backup['categories']! as List).last, {
      'id': int.parse(gifts.id),
      'name': 'Gifts',
      'kind': 'spending',
      'isArchived': false,
      'planGroup': 'savings',
      'isPlanArchived': false,
      'isPlanDeleted': false,
      'linkedAccountId': null,
    });
    expect(backup['transactions'], [
      {
        'id': 1,
        'type': 'spending',
        'amountMinor': 50025,
        'currencyCode': 'PHP',
        'date': '2026-11-10',
        'payee': 'SM Supermarket',
        'categoryId': int.parse(gifts.id),
        'sourceAccountId': int.parse(card.id),
        'destinationAccountId': null,
        'note': 'Birthday',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'updatedAt': '2026-11-16T09:30:00.000Z',
      },
      {
        'id': 2,
        'type': 'transfer',
        'amountMinor': 200000,
        'currencyCode': 'PHP',
        'date': '2026-11-11',
        'payee': '',
        'categoryId': null,
        'sourceAccountId': int.parse(bdo.id),
        'destinationAccountId': int.parse(gcash.id),
        'note': '',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'updatedAt': '2026-11-16T09:30:00.000Z',
      },
    ]);
    expect(backup['monthlyPlans'], [
      {
        'id': 1,
        'month': '2026-11',
        'categoryId': int.parse(gifts.id),
        'targetAmountMinor': null,
        'assignedAmountMinor': 100000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'updatedAt': '2026-11-16T09:30:00.000Z',
      },
    ]);
    expect(backup.keys, isNot(contains('balances')), reason: 'derived data');
  });

  test('createFile names the file by local date and holds the JSON', () async {
    final localNow = DateTime(2026, 11, 17, 23, 59);
    final file = await BackupExporter(
      database,
      clock: () => localNow,
    ).createFile();

    expect(file.fileName, 'fundly-backup-2026-11-17.json');
    final decoded = jsonDecode(file.contents) as Map<String, Object?>;
    expect(decoded['app'], 'fundly');
    expect(decoded['categories'], hasLength(9));
    expect(file.contents, startsWith('{\n  "app": "fundly",'));
  });

  test('a reset checkpoint is named by local date and time', () async {
    final exporter = BackupExporter(
      database,
      clock: () => DateTime(2026, 11, 22, 9, 5),
    );

    final checkpoint = await exporter.createFile(
      kind: BackupFileKind.resetCheckpoint,
    );

    expect(checkpoint.fileName, '2026-11-22_0905_reset_checkpoint.json');
    expect(checkpoint.contents, (await exporter.createFile()).contents);
  });
}
