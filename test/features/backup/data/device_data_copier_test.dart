import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_source.dart';
import 'package:fundly/features/backup/data/cloud_dataset_import.dart';
import 'package:fundly/features/backup/data/dataset_request.dart';
import 'package:fundly/features/backup/data/device_data_copier.dart';

import '../../../helpers/fake_import_server.dart';
import '../../../helpers/fake_synced_store.dart';

const user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

/// Returns fixed records instead of opening a database.
class FixedDeviceReader extends DeviceDataReader {
  FixedDeviceReader(this.records) : super(() => throw UnimplementedError());

  BackupRecords records;

  @override
  Future<BackupRecords> read() async => records;
}

void main() {
  late FakeSyncedStore store;
  late FakeImportServer server;
  late DeviceDataCopier copier;

  setUp(() {
    store = FakeSyncedStore(user);
    server = FakeImportServer(store);
    copier = DeviceDataCopier(
      import: CloudDatasetImport(
        importDataset: server.importDataset,
        userId: user.userId,
        wait: (_) async {},
      ),
      synced: store.database,
      device: FixedDeviceReader(sampleDeviceRecords()),
    );
  });
  tearDown(() => store.close());

  Future<CopyCheck?> copyAndCheck({
    Duration wait = const Duration(seconds: 2),
  }) async {
    final preview = await copier.preview();
    final sent = await copier.send(preview);
    return copier.check(
      source: preview.device,
      ids: sent.ids,
      counts: sent.counts,
      wait: wait,
    );
  }

  group('preview', () {
    test('an account with only server defaults is empty', () async {
      await store.download({'categories': serverDefaults()});
      final preview = await copier.preview();
      expect(preview.accountIsEmpty, isTrue);
      expect(preview.account.categories, 9);
      expect(preview.deviceCounts, countsOf(sampleDeviceRecords()));
    });

    test(
      'a changed default or any record makes the account non-empty',
      () async {
        final changed = serverDefaults()..[0]['revision'] = 2;
        await store.download({'categories': changed});
        expect((await copier.preview()).accountIsEmpty, isFalse);

        final other = FakeSyncedStore(user);
        addTearDown(other.close);
        await other.download({
          'accounts': [SyncedRows.account('a1', 'Cash')],
        });
        expect(await accountHoldsOnlyDefaults(other.database), isFalse);
      },
    );
  });

  group('send', () {
    test('copies into an empty account without expected counts', () async {
      await store.download({'categories': serverDefaults()});
      final preview = await copier.preview();
      final sent = await copier.send(preview);
      final request = server.requests.single.request;
      expect(request['mode'], 'into_empty');
      expect(request.containsKey('expected'), isFalse);
      expect(sent.counts, preview.deviceCounts);
      expect(sent.ids['transactions'], hasLength(5));
    });

    test('replaces a non-empty account with the counts the user saw', () async {
      await store.download({
        'accounts': [SyncedRows.account('a1', 'Cash')],
        'categories': serverDefaults(),
      });
      final preview = await copier.preview();
      await copier.send(preview);
      final request = server.requests.single.request;
      expect(request['mode'], 'replace');
      expect(request['expected'], countsJson(preview.account));
    });

    test('refuses a request over 8 MiB before sending it', () async {
      final records = sampleDeviceRecords();
      final note = 'x' * 500;
      final big = (
        customAccountTypes: records.customAccountTypes,
        accounts: records.accounts,
        categories: records.categories,
        monthlyPlans: records.monthlyPlans,
        transactions: [
          for (var n = 0; n < 20000; n++)
            (
              id: 100 + n,
              type: 'spending',
              amountMinor: 100,
              currencyCode: 'PHP',
              date: '2026-11-10',
              payee: 'Shop',
              categoryId: 1,
              sourceAccountId: 1,
              destinationAccountId: null,
              note: note,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
        ],
      );
      copier = DeviceDataCopier(
        import: CloudDatasetImport(
          importDataset: server.importDataset,
          userId: user.userId,
        ),
        synced: store.database,
        device: FixedDeviceReader(big),
      );
      final preview = await copier.preview();
      await expectLater(
        copier.send(preview),
        throwsA(
          isA<CopyTooLargeException>().having(
            (e) => e.bytes,
            'bytes',
            greaterThan(maxImportRequestBytes),
          ),
        ),
      );
      expect(server.requests, isEmpty);
    });

    test('a changed account is reported as such, never retried', () async {
      for (final code in ['dataset_changed', 'dataset_not_empty']) {
        server.failNext = importRefusal(code);
        final preview = await copier.preview();
        await expectLater(
          copier.send(preview),
          throwsA(
            isA<CloudImportException>().having(
              (e) => e.problem,
              'problem',
              CloudImportProblem.datasetChanged,
            ),
          ),
        );
      }
      expect(server.requests, hasLength(2));
    });

    test('a lost response is resent with the same ID and body', () async {
      server.failNext = const SocketException('lost');
      await copier.send(await copier.preview());
      expect(server.requests, hasLength(2));
      expect(server.requests[0].importId, server.requests[1].importId);
      expect(server.requests[0].request, same(server.requests[1].request));
    });
  });

  group('check', () {
    test('passes when the download matches every record', () async {
      final check = await copyAndCheck();
      expect(check, isNotNull);
      expect(check!.difference, isNull);
      expect(check.passed, isTrue);
      expect(check.accountBalances, check.deviceBalances);
      expect(
        check.deviceBalances['GCash'],
        const Money(minorUnits: 200000, currencyCode: 'PHP'),
      );
    });

    test('names the first difference the download holds', () async {
      server.tamper = (table, row) {
        if (table == 'monthly_plans' &&
            row['assigned_amount_minor'] == 600000) {
          row['assigned_amount_minor'] = 600001;
        }
      };
      final check = await copyAndCheck();
      expect(check!.passed, isFalse);
      expect(check.difference, 'monthly_plans 1: assignedAmountMinor');
    });

    test('returns null when the download does not arrive in time', () async {
      server.downloads = false;
      expect(
        await copyAndCheck(wait: const Duration(milliseconds: 50)),
        isNull,
      );
    });
  });

  test(
    'DeviceDataReader opens the signed-out database only to read it',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final directory = await Directory.systemTemp.createTemp('fundly-reader');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/fundly.sqlite');
      final seed = AppDatabase(NativeDatabase(file));
      await AccountRepository(seed).create(
        name: 'Cash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: const Money(minorUnits: 500, currencyCode: 'PHP'),
      );
      await seed.close();

      final opened = <AppDatabase>[];
      final reader = DeviceDataReader(() {
        final database = AppDatabase(NativeDatabase(file));
        opened.add(database);
        return database;
      });
      final both = await Future.wait([reader.read(), reader.read()]);
      expect(both.map((records) => records.accounts.single.name), [
        'Cash',
        'Cash',
      ]);
      expect(hasDeviceData(both.first), isTrue);
      expect(opened, hasLength(2));
      // Each connection was closed after its read, so a third can open.
      expect((await reader.read()).accounts, hasLength(1));
    },
  );
}
