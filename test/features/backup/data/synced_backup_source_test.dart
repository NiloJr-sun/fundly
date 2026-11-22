import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/synced_backup_source.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_synced_store.dart';

const user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

// Readable stand-ins for server UUIDs.
const wallet = 'c0000000-0000-4000-8000-000000000001';
const bdo = 'a0000000-0000-4000-8000-000000000001';
const card = 'a0000000-0000-4000-8000-000000000002';
const gcash = 'a0000000-0000-4000-8000-000000000003';
const food = 'b0000000-0000-4000-8000-000000000001';
const cardRow = 'b0000000-0000-4000-8000-000000000002';
const salary = 'b0000000-0000-4000-8000-000000000003';

void main() {
  // Some tests open a second store or a local database for comparison.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeSyncedStore store;
  final exportedAt = DateTime.utc(2026, 11, 22, 6, 30);

  setUp(() async {
    store = FakeSyncedStore(user);
    await store.download({
      'custom_account_types': [SyncedRows.customType(wallet, 'E-wallet')],
      'accounts': [
        SyncedRows.account(
          bdo,
          'BDO Savings',
          openingMinor: 1500000,
          budget: true,
        ),
        SyncedRows.account(
          card,
          'RCBC Credit',
          type: 'credit',
          openingMinor: -300000,
        ),
        SyncedRows.account(
          gcash,
          'GCash',
          customTypeId: wallet,
          archived: true,
        ),
      ],
      'categories': [
        SyncedRows.category(food, 'Food', planArchived: true),
        SyncedRows.category(
          cardRow,
          'RCBC Credit',
          planGroup: 'liability',
          linkedAccountId: card,
        ),
        SyncedRows.category(
          salary,
          'Salary',
          kind: 'inflow',
          createdAt: '2026-11-16T10:00:00+00:00',
        ),
      ],
      'transactions': [
        SyncedRows.transaction(
          'd0000000-0000-4000-8000-000000000001',
          amountMinor: 50025,
          date: '0001-01-01 BC',
          payee: 'SM Supermarket',
          categoryId: food,
          sourceAccountId: card,
          createdAt: '2026-11-16 12:00:00.123456+00',
        ),
        SyncedRows.transaction(
          'd0000000-0000-4000-8000-000000000002',
          type: 'creditCardPayment',
          amountMinor: 300000,
          date: '2026-11-20',
          payee: '',
          sourceAccountId: bdo,
          destinationAccountId: card,
        ),
      ],
      'monthly_plans': [
        SyncedRows.plan(
          'e0000000-0000-4000-8000-000000000001',
          categoryId: cardRow,
          assignedMinor: 300000,
        ),
        SyncedRows.plan(
          'e0000000-0000-4000-8000-000000000002',
          categoryId: food,
          month: '2026-12',
          targetMinor: 500000,
          assignedMinor: 250000,
        ),
      ],
    });
  });

  tearDown(() => store.close());

  Future<Map<String, Object?>> export() => BackupExporter.from(
    SyncedBackupSource(store.database),
    clock: () => exportedAt,
  ).export();

  test('writes format 7 with the synced store schema version', () async {
    final backup = await export();

    expect(backup['app'], 'fundly');
    expect(backup['formatVersion'], BackupExporter.syncedFormatVersion);
    expect(backup['formatVersion'], 7);
    expect(backup['schemaVersion'], store.database.schemaVersion);
    expect(backup['exportedAt'], '2026-11-22T06:30:00.000Z');
  });

  test('every record keeps its UUID and its references', () async {
    final backup = await export();

    expect(backup['customAccountTypes'], [
      {
        'id': wallet,
        'name': 'E-wallet',
        'baseType': 'savingsCash',
        'createdAt': '2026-11-16T09:30:00.000Z',
      },
    ]);
    expect(backup['accounts'], [
      {
        'id': bdo,
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
        'id': card,
        'name': 'RCBC Credit',
        'type': 'credit',
        'customTypeId': null,
        'openingBalanceMinor': -300000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'isArchived': false,
        'isBudgetAccount': false,
      },
      {
        'id': gcash,
        'name': 'GCash',
        'type': 'savingsCash',
        'customTypeId': wallet,
        'openingBalanceMinor': 0,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'isArchived': true,
        'isBudgetAccount': false,
      },
    ]);
    expect(backup['categories'], [
      {
        'id': food,
        'name': 'Food',
        'kind': 'spending',
        'isArchived': false,
        'isPlanArchived': true,
        'isPlanDeleted': false,
        'planGroup': 'spending',
        'linkedAccountId': null,
      },
      {
        'id': cardRow,
        'name': 'RCBC Credit',
        'kind': 'spending',
        'isArchived': false,
        'isPlanArchived': false,
        'isPlanDeleted': false,
        'planGroup': 'liability',
        'linkedAccountId': card,
      },
      {
        'id': salary,
        'name': 'Salary',
        'kind': 'inflow',
        'isArchived': false,
        'isPlanArchived': false,
        'isPlanDeleted': false,
        'planGroup': 'spending',
        'linkedAccountId': null,
      },
    ]);
    expect(backup['transactions'], [
      {
        'id': 'd0000000-0000-4000-8000-000000000001',
        'type': 'spending',
        'amountMinor': 50025,
        'currencyCode': 'PHP',
        'date': '0000-01-01',
        'payee': 'SM Supermarket',
        'categoryId': food,
        'sourceAccountId': card,
        'destinationAccountId': null,
        'note': '',
        'createdAt': '2026-11-16T12:00:00.123456Z',
        'updatedAt': '2026-11-16T12:00:00.123456Z',
      },
      {
        'id': 'd0000000-0000-4000-8000-000000000002',
        'type': 'creditCardPayment',
        'amountMinor': 300000,
        'currencyCode': 'PHP',
        'date': '2026-11-20',
        'payee': '',
        'categoryId': null,
        'sourceAccountId': bdo,
        'destinationAccountId': card,
        'note': '',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'updatedAt': '2026-11-16T09:30:00.000Z',
      },
    ]);
    expect(backup['monthlyPlans'], [
      {
        'id': 'e0000000-0000-4000-8000-000000000001',
        'month': '2026-11',
        'categoryId': cardRow,
        'targetAmountMinor': null,
        'assignedAmountMinor': 300000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'updatedAt': '2026-11-16T09:30:00.000Z',
      },
      {
        'id': 'e0000000-0000-4000-8000-000000000002',
        'month': '2026-12',
        'categoryId': food,
        'targetAmountMinor': 500000,
        'assignedAmountMinor': 250000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'updatedAt': '2026-11-16T09:30:00.000Z',
      },
    ]);
  });

  test('has the same keys as format 6, so one reader can serve both', () async {
    final local = AppDatabase(NativeDatabase.memory());
    addTearDown(local.close);
    final format6 = await BackupExporter(local).export();
    final format7 = await export();

    expect(format7.keys, format6.keys);
  });

  test('the file is indented JSON with the usual names', () async {
    final exporter = BackupExporter.from(
      SyncedBackupSource(store.database),
      clock: () => DateTime(2026, 11, 22, 14, 30),
    );

    final backup = await exporter.createFile();
    final checkpoint = await exporter.createFile(
      kind: BackupFileKind.resetCheckpoint,
    );

    expect(backup.fileName, 'fundly-backup-2026-11-22.json');
    expect(checkpoint.fileName, '2026-11-22_1430_reset_checkpoint.json');
    final decoded = jsonDecode(backup.contents) as Map<String, Object?>;
    expect(decoded['formatVersion'], 7);
    expect(backup.contents, startsWith('{\n  "app": "fundly",'));
  });

  test('an empty account exports empty lists', () async {
    final empty = FakeSyncedStore(user);
    addTearDown(empty.close);

    final backup = await BackupExporter.from(SyncedBackupSource(empty.database))
        .export();

    for (final key in [
      'customAccountTypes',
      'accounts',
      'categories',
      'transactions',
      'monthlyPlans',
    ]) {
      expect(backup[key], isEmpty, reason: key);
    }
  });

  group('backupExporterProvider', () {
    test('signed in, it exports the synchronized store (format 7)', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: user),
          ),
          syncedStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      final backup = await container.read(backupExporterProvider).export();

      expect(backup['formatVersion'], 7);
      expect((backup['accounts']! as List<Object?>), hasLength(3));
    });

    test('signed out, it exports this device (format 6)', () async {
      final local = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          syncedStoreProvider.overrideWithValue(null),
          appDatabaseProvider.overrideWithValue(local),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await local.close();
      });

      final backup = await container.read(backupExporterProvider).export();

      expect(backup['formatVersion'], 6);
    });
  });
}
