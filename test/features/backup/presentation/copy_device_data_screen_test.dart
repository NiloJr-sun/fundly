import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/cloud_dataset_import.dart';
import 'package:fundly/features/backup/data/device_copy_store.dart';
import 'package:fundly/features/backup/data/device_data_copier.dart';
import 'package:fundly/features/backup/presentation/copy_device_data_screen.dart';
import 'package:fundly/features/backup/presentation/device_data_prompt.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';
import 'package:fundly/features/backup/presentation/restore_backup.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';
import 'package:fundly/features/spaces/data/active_space_store.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_import_server.dart';
import '../../../helpers/fake_synced_store.dart';
import '../../../helpers/provider_overrides.dart';
import '../data/device_data_copier_test.dart' show FixedDeviceReader;

const user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

class FakeCheckpointExporter implements BackupExporter {
  final kinds = <BackupFileKind>[];

  @override
  Future<BackupFile> createFile({
    BackupFileKind kind = BackupFileKind.backup,
  }) async {
    kinds.add(kind);
    return const BackupFile(
      fileName: '2026-11-22_1430_replace_checkpoint.json',
      contents: '{"formatVersion": 7}',
    );
  }

  @override
  Future<Map<String, Object?>> export() async => const {};
}

/// Lets the database work (real async) and the frames (fake time) run in
/// turns. The screen's spinner never settles, so pumpAndSettle cannot be used.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const deviceSummary =
    '4 accounts · 1 account type · 5 categories · 5 transactions · 2 plans';

void main() {
  late FakeSyncedStore store;
  late FakeImportServer server;
  late FixedDeviceReader device;
  late InMemoryDeviceCopyStore copies;
  late FakeCheckpointExporter exporter;

  setUp(() {
    store = FakeSyncedStore(user);
    server = FakeImportServer(store);
    device = FixedDeviceReader(sampleDeviceRecords());
    copies = InMemoryDeviceCopyStore();
    exporter = FakeCheckpointExporter();
  });
  tearDown(() => store.close());

  List<Override> overrides({
    AuthIdentity identity = user,
    bool canCopy = true,
  }) => [
    ...noAccounts(),
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(initial: identity),
    ),
    if (identity is SignedIn) syncedStoreProvider.overrideWithValue(store),
    deviceDataReaderProvider.overrideWithValue(device),
    deviceCopyStoreProvider.overrideWithValue(copies),
    backupExporterProvider.overrideWithValue(exporter),
    shareBackupFileProvider.overrideWithValue((file, {origin}) async => true),
    copyCheckWaitProvider.overrideWithValue(const Duration(milliseconds: 200)),
    deviceDataCopierProvider.overrideWith(
      (ref) => canCopy && identity is SignedIn
          ? DeviceDataCopier(
              import: CloudDatasetImport(
                importDataset: server.importDataset,
                userId: user.userId,
                wait: (_) async {},
              ),
              synced: store.database,
              device: device,
            )
          : null,
    ),
  ];

  Future<void> seedEmptyAccount(WidgetTester tester) =>
      tester.runAsync(() => store.download({'categories': serverDefaults()}));

  Future<void> seedUsedAccount(WidgetTester tester) => tester.runAsync(
    () => store.download({
      'accounts': [SyncedRows.account('a1', 'Cash')],
      'categories': serverDefaults(),
    }),
  );

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => openCopyDeviceData(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await settle(tester);
  }

  testWidgets('an empty account shows both counts and offers Copy', (
    tester,
  ) async {
    await seedEmptyAccount(tester);
    await openScreen(tester);

    expect(find.text('On this device'), findsOneWidget);
    expect(find.text(deviceSummary), findsOneWidget);
    expect(find.text('In your account (a@test.com)'), findsOneWidget);
    expect(
      find.text(
        '0 accounts · 0 account types · 9 categories · 0 transactions · 0 plans',
      ),
      findsOneWidget,
    );
    expect(find.text('Copy to my account'), findsOneWidget);
    expect(find.text("Replace my account's data"), findsNothing);
  });

  testWidgets('Copy sends into_empty, checks and remembers the copy', (
    tester,
  ) async {
    await seedEmptyAccount(tester);
    await openScreen(tester);

    await tester.tap(find.text('Copy to my account'));
    await settle(tester);

    expect(server.requests.single.request['mode'], 'into_empty');
    expect(find.text('Copied and checked'), findsOneWidget);
    expect(find.text('GCash'), findsOneWidget);
    expect(find.text('Same in your account'), findsNWidgets(4));
    final state = copies.read();
    expect(state.lastCopy?.email, 'a@test.com');
    expect(state.pending, isNull);
    expect(exporter.kinds, isEmpty);
  });

  testWidgets('Replace needs a checkpoint and the phrase, then sends replace', (
    tester,
  ) async {
    await seedUsedAccount(tester);
    await openScreen(tester);

    await tester.tap(find.text("Replace my account's data"));
    await settle(tester);
    expect(find.text("Replace your account's data?"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining(
          'on every device signed in as a@test.com',
        ),
      ),
      findsOneWidget,
    );
    final replace = find.widgetWithText(FilledButton, 'Replace');
    expect(tester.widget<FilledButton>(replace).onPressed, isNull);

    await tester.tap(find.text('Export checkpoint'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Replace my data ');
    await tester.pump();
    await tester.tap(replace);
    await settle(tester);

    expect(exporter.kinds, [BackupFileKind.replaceCheckpoint]);
    final request = server.requests.single.request;
    expect(request['mode'], 'replace');
    expect(request['expected'], {
      'custom_account_types': 0,
      'accounts': 1,
      'categories': 9,
      'transactions': 0,
      'monthly_plans': 0,
    });
    expect(find.text('Copied and checked'), findsOneWidget);
  });

  testWidgets('cancelling Replace sends nothing', (tester) async {
    await seedUsedAccount(tester);
    await openScreen(tester);

    await tester.tap(find.text("Replace my account's data"));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(server.requests, isEmpty);
    expect(find.text("Replace my account's data"), findsOneWidget);
  });

  testWidgets('a changed account reloads the preview and says why', (
    tester,
  ) async {
    await seedEmptyAccount(tester);
    await openScreen(tester);
    server.failNext = importRefusal('dataset_not_empty');

    await tester.tap(find.text('Copy to my account'));
    await settle(tester);

    expect(
      find.textContaining('Your account changed on another device'),
      findsOneWidget,
    );
    expect(find.text('Copy to my account'), findsOneWidget);
    expect(copies.read().pending, isNull);
  });

  testWidgets('a refusal says nothing changed', (tester) async {
    await seedEmptyAccount(tester);
    await openScreen(tester);
    server.failNext = importRefusal('invalid_import');

    await tester.tap(find.text('Copy to my account'));
    await settle(tester);

    expect(
      find.text('The copy was refused (invalid_import). Nothing was changed.'),
      findsOneWidget,
    );
  });

  testWidgets('waiting uploads block copying before anything is read', (
    tester,
  ) async {
    store.pendingUploads = 2;
    await seedEmptyAccount(tester);
    await openScreen(tester);

    expect(
      find.textContaining('Some changes are still waiting to upload'),
      findsOneWidget,
    );
    expect(find.text('Copy to my account'), findsNothing);
  });

  testWidgets('offline, copying waits for a connection', (tester) async {
    store.state = const SyncState(
      connection: SyncConnection.offline,
      hasSynced: true,
    );
    await seedEmptyAccount(tester);
    await openScreen(tester);

    expect(
      find.text(
        "You're offline. Connect to the internet to change your account's data.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('a device with only defaults has nothing to copy', (
    tester,
  ) async {
    final records = sampleDeviceRecords();
    device.records = (
      customAccountTypes: const [],
      accounts: const [],
      categories: [
        for (final c in records.categories)
          if (c.name == 'Food & Groceries' || c.name == 'Salary') c,
      ],
      transactions: const [],
      monthlyPlans: const [],
    );
    await seedEmptyAccount(tester);
    await openScreen(tester);

    expect(find.textContaining("There's nothing to copy"), findsOneWidget);
  });

  testWidgets('a late download is checked the next time the screen opens', (
    tester,
  ) async {
    await seedEmptyAccount(tester);
    server.downloads = false;
    await openScreen(tester);

    await tester.tap(find.text('Copy to my account'));
    await settle(tester);
    expect(
      find.textContaining('Copied. This device will check it'),
      findsOneWidget,
    );
    expect(copies.read().pending?.userId, user.userId);
    expect(copies.read().lastCopy, isNull);

    // The download arrives; opening the screen again runs the check.
    final request = server.requests.single.request;
    server.downloads = true;
    final arrived = server.importDataset(
      userId: user.userId,
      importId: 'again',
      request: request,
    );
    await settle(tester);
    await arrived;
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Open'));
    await settle(tester);

    expect(find.text('Copied and checked'), findsOneWidget);
    expect(copies.read().pending, isNull);
    expect(copies.read().lastCopy?.userId, user.userId);
  });

  testWidgets('a difference is shown and nothing is remembered as copied', (
    tester,
  ) async {
    await seedEmptyAccount(tester);
    server.tamper = (table, row) {
      if (table == 'accounts' && row['name'] == 'GCash') row['name'] = 'G';
    };
    await openScreen(tester);

    await tester.tap(find.text('Copy to my account'));
    await settle(tester);

    expect(find.text("The copy doesn't match this device"), findsOneWidget);
    expect(
      find.textContaining('First difference: accounts 2: name'),
      findsOneWidget,
    );
    expect(copies.read().lastCopy, isNull);
    expect(copies.read().pending, isNull);
  });

  group('the sign-in prompt', () {
    Future<void> pumpShell(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(
            home: DeviceDataPrompt(child: Scaffold(body: Text('Home'))),
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('appears once after the first download, Not now is kept', (
      tester,
    ) async {
      await seedEmptyAccount(tester);
      await pumpShell(tester);

      expect(find.text("Copy this device's data?"), findsOneWidget);
      expect(find.textContaining('(a@test.com)'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await settle(tester);

      expect(copies.read().dismissed, {user.userId});
      store.state = const SyncState(
        connection: SyncConnection.connected,
        hasSynced: true,
        lastSyncedAt: null,
        uploadRetry: 'x',
      );
      await settle(tester);
      expect(find.text("Copy this device's data?"), findsNothing);
    });

    testWidgets('waits while another space than Personal is shown '
        '(shared spaces C2)', (tester) async {
      await seedEmptyAccount(tester);
      final remembered = InMemoryActiveSpaceStore();
      await remembered.remember(
        user.userId,
        '7c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            activeSpaceStoreProvider.overrideWithValue(remembered),
          ],
          child: const MaterialApp(
            home: DeviceDataPrompt(child: Scaffold(body: Text('Home'))),
          ),
        ),
      );
      await settle(tester);

      expect(find.text("Copy this device's data?"), findsNothing);
      expect(copies.read().dismissed, isEmpty);
    });

    testWidgets('Review opens the copy screen', (tester) async {
      await seedEmptyAccount(tester);
      await pumpShell(tester);

      await tester.tap(find.text('Review'));
      await settle(tester);

      expect(find.text('Copy to my account'), findsOneWidget);
      expect(copies.read().dismissed, isEmpty);
    });

    testWidgets('waits for the first download', (tester) async {
      store.state = const SyncState(connection: SyncConnection.connected);
      await pumpShell(tester);
      expect(find.text("Copy this device's data?"), findsNothing);

      store.state = const SyncState(
        connection: SyncConnection.connected,
        hasSynced: true,
      );
      await settle(tester);
      expect(find.text("Copy this device's data?"), findsOneWidget);
    });

    testWidgets('stays quiet for an account already copied to', (tester) async {
      await copies.write(
        DeviceCopyState(
          copies: [
            DeviceCopy(
              userId: user.userId,
              email: user.email,
              copiedAt: DateTime.utc(2026, 11, 22),
            ),
          ],
        ),
      );
      await pumpShell(tester);
      expect(find.text("Copy this device's data?"), findsNothing);
    });

    testWidgets('stays quiet without data on this device', (tester) async {
      device.records = (
        customAccountTypes: const [],
        accounts: const [],
        categories: const [],
        transactions: const [],
        monthlyPlans: const [],
      );
      await pumpShell(tester);
      expect(find.text("Copy this device's data?"), findsNothing);
    });
  });

  group('restoring a backup while signed in (S6.3)', () {
    late String file;

    Future<void> pumpProfile(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            pickBackupFileProvider.overrideWithValue(() async => file),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await settle(tester);
    }

    Future<void> tapRestore(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Restore from backup'));
      await tester.tap(find.text('Restore from backup'));
      await settle(tester);
    }

    testWidgets(
      'a format 7 file restores into an empty account and checks out',
      (tester) async {
        file = jsonEncode(await sampleBackupJson());
        await seedEmptyAccount(tester);
        await pumpProfile(tester);
        await tapRestore(tester);

        expect(find.text('Restore a backup'), findsOneWidget);
        expect(find.text('In the backup (Nov 17, 2026)'), findsOneWidget);
        expect(find.text(deviceSummary), findsOneWidget);
        await tester.tap(find.text('Restore into my account'));
        await settle(tester);

        expect(server.requests.single.request['mode'], 'into_empty');
        expect(find.text('Restored and checked'), findsOneWidget);
        // Only a copy of this device's data is remembered.
        expect(copies.read().lastCopy, isNull);
        expect(copies.read().pending, isNull);
      },
    );

    testWidgets('a format 3 file replaces a used account', (tester) async {
      file = jsonEncode(await sampleFormat3Json());
      await seedUsedAccount(tester);
      await pumpProfile(tester);
      await tapRestore(tester);

      await tester.tap(find.text("Replace my account's data"));
      await settle(tester);
      expect(
        find.textContaining("then replaced with the backup's data."),
        findsOneWidget,
      );
      await tester.tap(find.text('Export checkpoint'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'replace my data');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await settle(tester);

      expect(server.requests.single.request['mode'], 'replace');
      expect(find.text('Restored and checked'), findsOneWidget);
    });

    testWidgets('a late download says so and keeps no check', (tester) async {
      file = jsonEncode(await sampleBackupJson());
      server.downloads = false;
      await seedEmptyAccount(tester);
      await pumpProfile(tester);
      await tapRestore(tester);

      await tester.tap(find.text('Restore into my account'));
      await settle(tester);

      expect(
        find.text('Restored. This device will show it after it syncs.'),
        findsOneWidget,
      );
      expect(copies.read().pending, isNull);
    });

    testWidgets('an invalid file is refused before anything is sent', (
      tester,
    ) async {
      final backup = await sampleBackupJson();
      ((backup['accounts']! as List).first as Map<String, Object?>)['id'] = '2';
      file = jsonEncode(backup);
      await seedEmptyAccount(tester);
      await pumpProfile(tester);
      await tapRestore(tester);

      expect(
        find.textContaining('This backup has invalid data'),
        findsOneWidget,
      );
      expect(find.text('Restore a backup'), findsNothing);
      expect(server.requests, isEmpty);
    });
  });

  group('Profile', () {
    Future<void> pumpProfile(
      WidgetTester tester, {
      AuthIdentity identity = user,
      bool canCopy = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(identity: identity, canCopy: canCopy),
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await settle(tester);
    }

    testWidgets('signed in with data offers the copy', (tester) async {
      await seedEmptyAccount(tester);
      await pumpProfile(tester);

      expect(find.text("Copy this device's data"), findsOneWidget);
      await tester.tap(find.text("Copy this device's data"));
      await settle(tester);
      expect(find.text('Copy to my account'), findsOneWidget);
    });

    testWidgets('no row without the cloud configuration', (tester) async {
      await pumpProfile(tester, canCopy: false);
      expect(find.text("Copy this device's data"), findsNothing);
    });

    testWidgets('signed out says where the data was copied', (tester) async {
      await copies.write(
        DeviceCopyState(
          copies: [
            DeviceCopy(
              userId: user.userId,
              email: user.email,
              copiedAt: DateTime(2026, 11, 22, 15),
            ),
          ],
        ),
      );
      await pumpProfile(tester, identity: const SignedOut());

      expect(
        find.text(
          "This device's data was copied to a@test.com on Nov 22, 2026.",
        ),
        findsOneWidget,
      );
      expect(find.text("Copy this device's data"), findsNothing);
    });
  });
}
