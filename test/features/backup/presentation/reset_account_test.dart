import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/cloud_data_resetter.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';
import 'package:fundly/features/backup/presentation/reset_data.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_synced_store.dart';
import '../../../helpers/provider_overrides.dart';

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
      fileName: '2026-11-22_1430_reset_checkpoint.json',
      contents: '{"formatVersion": 7}',
    );
  }

  @override
  Future<Map<String, Object?>> export() async => const {};
}

Map<String, Object?> resultWith(BackupCounts counts) => {
  'version': 1,
  'mode': 'replace',
  'counts': {
    'custom_account_types': counts.customAccountTypes,
    'accounts': counts.accounts,
    'categories': counts.categories,
    'transactions': counts.transactions,
    'monthly_plans': counts.monthlyPlans,
  },
};

void main() {
  late FakeSyncedStore store;
  late FakeCheckpointExporter exporter;
  late List<Map<String, Object?>> requests;

  /// What the fake server does with a request; returns its result.
  late Map<String, Object?> Function() server;

  setUp(() {
    store = FakeSyncedStore(user);
    exporter = FakeCheckpointExporter();
    requests = [];
    server = () => resultWith(freshAccountCounts);
  });
  tearDown(() => store.close());

  /// Two accounts, one category, one transaction in the account.
  Future<void> seedAccount(WidgetTester tester) => tester.runAsync(
    () => store.download({
      'accounts': [
        SyncedRows.account('a1', 'BDO'),
        SyncedRows.account('a2', 'GCash'),
      ],
      'categories': [SyncedRows.category('c1', 'Food')],
      'transactions': [
        SyncedRows.transaction('x1', categoryId: 'c1', sourceAccountId: 'a1'),
      ],
    }),
  );

  Future<void> pumpProfile(
    WidgetTester tester, {
    bool cloudConfigured = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: user),
          ),
          syncedStoreProvider.overrideWithValue(store),
          backupExporterProvider.overrideWithValue(exporter),
          shareBackupFileProvider.overrideWithValue(
            (file, {origin}) async => true,
          ),
          cloudDataResetterProvider.overrideWithValue(
            cloudConfigured
                ? CloudDataResetter(
                    importDataset:
                        ({
                          required userId,
                          required importId,
                          required request,
                        }) async {
                          requests.add(request);
                          return server();
                        },
                    userId: user.userId,
                    wait: (_) async {},
                  )
                : null,
          ),
          resetSyncWaitProvider.overrideWithValue(
            const Duration(milliseconds: 100),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapReset(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Reset all data'));
    await tester.pump();
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Export checkpoint'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'delete my data');
    await tester.pump();
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
  }

  testWidgets('the tile and dialog speak about the whole account', (
    tester,
  ) async {
    await seedAccount(tester);
    await pumpProfile(tester);

    expect(find.text('Delete every record in your account'), findsOneWidget);
    await tapReset(tester);

    expect(find.text('In your account'), findsOneWidget);
    expect(
      find.text(
        '2 accounts · 0 account types · 1 category · 1 transaction · 0 plans',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('on every device signed in as a@test.com'),
      findsOneWidget,
    );
    expect(requests, isEmpty);
  });

  testWidgets('a checkpoint and the phrase reset the account on the server', (
    tester,
  ) async {
    await seedAccount(tester);
    await pumpProfile(tester);
    await tapReset(tester);

    await confirm(tester);

    expect(exporter.kinds, [BackupFileKind.resetCheckpoint]);
    expect(requests.single['mode'], 'replace');
    expect(requests.single['expected'], {
      'custom_account_types': 0,
      'accounts': 2,
      'categories': 1,
      'transactions': 1,
      'monthly_plans': 0,
    });
    // The fake server never downloads, so this phone has not caught up.
    expect(
      find.text('Deleted. This phone will show it after it syncs.'),
      findsOneWidget,
    );
    expect(find.text('Deleting your data…'), findsNothing);
  });

  testWidgets('says All data deleted once this phone has the reset data', (
    tester,
  ) async {
    await seedAccount(tester);
    await pumpProfile(tester);
    // As if the download already holds what the server reports.
    server = () => resultWith(
      const BackupCounts(
        customAccountTypes: 0,
        accounts: 2,
        categories: 1,
        transactions: 1,
        monthlyPlans: 0,
      ),
    );
    await tapReset(tester);

    await confirm(tester);

    expect(find.text('All data deleted'), findsOneWidget);
  });

  testWidgets('a change on another device deletes nothing and says so', (
    tester,
  ) async {
    await seedAccount(tester);
    await pumpProfile(tester);
    server = () => throw const PostgrestException(
      message: 'dataset_changed',
      code: 'P0001',
    );
    await tapReset(tester);

    await confirm(tester);

    expect(
      find.textContaining('Your data changed on another device'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a refused reset names the code', (tester) async {
    await pumpProfile(tester);
    server = () => throw const PostgrestException(
      message: 'invalid_import',
      code: 'P0001',
    );
    await tapReset(tester);

    await confirm(tester);

    expect(
      find.text('The reset was refused (invalid_import). Nothing was changed.'),
      findsOneWidget,
    );
  });

  for (final (name, arrange, message) in [
    (
      'changes waiting to upload',
      (FakeSyncedStore store) => store.pendingUploads = 1,
      'Some changes are still waiting to upload.',
    ),
    (
      'offline',
      (FakeSyncedStore store) => store.state = const SyncState(
        connection: SyncConnection.offline,
        hasSynced: true,
      ),
      "You're offline.",
    ),
    (
      'still downloading',
      (FakeSyncedStore store) =>
          store.state = const SyncState(connection: SyncConnection.connecting),
      "Your data hasn't finished downloading",
    ),
  ]) {
    testWidgets('$name: explains why and opens nothing', (tester) async {
      arrange(store);
      await pumpProfile(tester);

      await tapReset(tester);

      expect(find.textContaining(message), findsOneWidget);
      expect(find.text('Delete all your data?'), findsNothing);
      expect(requests, isEmpty);
    });
  }

  testWidgets('a build without the cloud configuration explains', (
    tester,
  ) async {
    await pumpProfile(tester, cloudConfigured: false);

    await tapReset(tester);

    expect(
      find.text('Resetting your account is not available in this version.'),
      findsOneWidget,
    );
  });
}
