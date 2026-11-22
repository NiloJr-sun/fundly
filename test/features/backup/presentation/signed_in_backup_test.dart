import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';
import 'package:fundly/features/backup/presentation/signed_in_backup.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_synced_store.dart';
import '../../../helpers/provider_overrides.dart';

const user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

const synced = SyncState(connection: SyncConnection.connected, hasSynced: true);

/// Returns a fixed format 7 file without reading a database.
class FakeSyncedExporter implements BackupExporter {
  int files = 0;

  @override
  Future<BackupFile> createFile({
    BackupFileKind kind = BackupFileKind.backup,
  }) async {
    files++;
    return const BackupFile(
      fileName: 'fundly-backup-2026-11-22.json',
      contents: '{"app": "fundly", "formatVersion": 7}\n',
    );
  }

  @override
  Future<Map<String, Object?>> export() async => const {};
}

void main() {
  group('signedInExportBlocker', () {
    SignedInExportBlocker? blocker({
      SyncState state = synced,
      int pending = 0,
      int unsafe = 0,
      bool isWeb = false,
    }) => signedInExportBlocker(
      state: state,
      pendingUploads: pending,
      unsafeRows: unsafe,
      isWeb: isWeb,
    );

    test('allows a fully synced store', () {
      expect(blocker(), isNull);
      expect(
        blocker(
          state: const SyncState(
            connection: SyncConnection.offline,
            hasSynced: true,
          ),
        ),
        isNull,
        reason: 'offline is fine once everything has synced',
      );
    });

    test('blocks while changes wait to upload', () {
      expect(blocker(pending: 1), SignedInExportBlocker.uploadsWaiting);
    });

    test('blocks while sync is stuck, before anything else', () {
      expect(
        blocker(
          state: const SyncState(connection: SyncConnection.stuck),
          pending: 3,
        ),
        SignedInExportBlocker.stuck,
      );
    });

    test('blocks before the first full download', () {
      expect(
        blocker(state: const SyncState(connection: SyncConnection.connecting)),
        SignedInExportBlocker.notDownloaded,
      );
    });

    test('blocks rows the browser cannot read, only on the web', () {
      expect(
        blocker(unsafe: 1, isWeb: true),
        SignedInExportBlocker.unreadableRows,
      );
      expect(blocker(unsafe: 1), isNull);
    });
  });

  late FakeSyncedStore store;
  late FakeSyncedExporter exporter;
  late List<BackupFile> shared;

  setUp(() {
    store = FakeSyncedStore(user);
    exporter = FakeSyncedExporter();
    shared = [];
  });
  tearDown(() => store.close());

  Future<void> pumpSignedInProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: user),
          ),
          syncedStoreProvider.overrideWithValue(store),
          backupExporterProvider.overrideWithValue(exporter),
          shareBackupFileProvider.overrideWithValue((file, {origin}) async {
            shared.add(file);
            return true;
          }),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapExport(WidgetTester tester) async {
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
  }

  testWidgets('signed in and synced, Export backup shares the file', (
    tester,
  ) async {
    await pumpSignedInProfile(tester);

    await tapExport(tester);

    expect(shared.single.contents, contains('"formatVersion": 7'));
    expect(find.text(signedInBackupSavedMessage), findsOneWidget);
  });

  for (final (name, setUpStore, blocker) in [
    (
      'changes waiting to upload',
      (FakeSyncedStore store) => store.pendingUploads = 2,
      SignedInExportBlocker.uploadsWaiting,
    ),
    (
      'sync stuck',
      (FakeSyncedStore store) => store.state = const SyncState(
        connection: SyncConnection.stuck,
        hasSynced: true,
      ),
      SignedInExportBlocker.stuck,
    ),
    (
      'no full download yet',
      (FakeSyncedStore store) =>
          store.state = const SyncState(connection: SyncConnection.connecting),
      SignedInExportBlocker.notDownloaded,
    ),
  ]) {
    testWidgets('$name: explains why and exports nothing', (tester) async {
      setUpStore(store);
      await pumpSignedInProfile(tester);

      await tapExport(tester);

      expect(find.text(signedInExportBlockerText(blocker)), findsOneWidget);
      expect(exporter.files, 0);
      expect(shared, isEmpty);
    });
  }
}
