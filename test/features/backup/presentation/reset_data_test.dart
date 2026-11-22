import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/data_resetter.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';
import 'package:fundly/features/backup/presentation/reset_data.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/provider_overrides.dart';

/// Reports fixed counts; nothing else is used by the reset flow.
class FakeCountsImporter implements BackupImporter {
  @override
  Future<BackupCounts> currentCounts() async => const BackupCounts(
    customAccountTypes: 1,
    accounts: 6,
    categories: 12,
    transactions: 131,
    monthlyPlans: 2,
  );

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records resets instead of touching a database.
class FakeDataResetter implements DataResetter {
  int resets = 0;
  bool fail = false;

  @override
  Future<void> resetAll() async {
    if (fail) throw StateError('database rejected the reset');
    resets++;
  }
}

class FakeBackupExporter implements BackupExporter {
  @override
  Future<BackupFile> createFile({
    BackupFileKind kind = BackupFileKind.backup,
  }) async => BackupFile(
    fileName: switch (kind) {
      BackupFileKind.backup => 'fundly-backup-2026-11-22.json',
      BackupFileKind.resetCheckpoint => '2026-11-22_1430_reset_checkpoint.json',
    },
    contents: '{}',
  );

  @override
  Future<Map<String, Object?>> export() async => const {};
}

void main() {
  group('confirmsReset', () {
    test('accepts the phrase, ignoring capitals and outer spaces', () {
      expect(confirmsReset('delete my data'), isTrue);
      expect(confirmsReset('Delete My Data'), isTrue);
      expect(confirmsReset('  DELETE MY DATA \n'), isTrue);
    });

    test('rejects anything else', () {
      expect(confirmsReset(''), isFalse);
      expect(confirmsReset('delete my dat'), isFalse);
      expect(confirmsReset('delete  my data'), isFalse);
      expect(confirmsReset('delete my data please'), isFalse);
      expect(confirmsReset('yes'), isFalse);
    });
  });

  late FakeDataResetter resetter;
  late List<BackupFile> shared;

  /// Whether the share sheet reports the file as saved (false: closed).
  late bool shareSaves;

  setUp(() {
    resetter = FakeDataResetter();
    shared = [];
    shareSaves = true;
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    AuthRepository auth = const LocalOnlyAuthRepository(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          authRepositoryProvider.overrideWithValue(auth),
          backupImporterProvider.overrideWithValue(FakeCountsImporter()),
          backupExporterProvider.overrideWithValue(FakeBackupExporter()),
          dataResetterProvider.overrideWithValue(resetter),
          shareBackupFileProvider.overrideWithValue((file, {origin}) async {
            shared.add(file);
            return shareSaves;
          }),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapReset(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Reset all data'));
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
  }

  FilledButton deleteButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Delete everything'),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  Future<void> exportCheckpoint(WidgetTester tester) async {
    await tester.tap(find.text('Export checkpoint'));
    await tester.pumpAndSettle();
  }

  bool fieldEnabled(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).enabled ?? true;

  testWidgets('shows what will be deleted, with everything locked', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tapReset(tester);

    expect(find.text('Delete all your data?'), findsOneWidget);
    expect(
      find.text(
        '6 accounts · 1 account type · 12 categories · 131 transactions · '
        '2 plans',
      ),
      findsOneWidget,
    );
    expect(find.text('1. Save a checkpoint'), findsOneWidget);
    expect(find.text('2. Type "delete my data" to confirm'), findsOneWidget);
    expect(fieldEnabled(tester), isFalse);
    expect(deleteButton(tester).onPressed, isNull);
  });

  testWidgets('the checkpoint is exported with its own file name', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tapReset(tester);

    await exportCheckpoint(tester);

    expect(shared.single.fileName, '2026-11-22_1430_reset_checkpoint.json');
    expect(find.text('Checkpoint saved'), findsOneWidget);
    expect(find.text('Export checkpoint'), findsNothing);
    expect(fieldEnabled(tester), isTrue);
    expect(deleteButton(tester).onPressed, isNull, reason: 'not typed yet');
    expect(resetter.resets, 0);
  });

  testWidgets('closing the share sheet does not unlock the reset', (
    tester,
  ) async {
    shareSaves = false;
    await pumpProfile(tester);
    await tapReset(tester);

    await exportCheckpoint(tester);

    expect(shared, hasLength(1));
    expect(find.text('Checkpoint saved'), findsNothing);
    expect(find.text('Export checkpoint'), findsOneWidget);
    expect(fieldEnabled(tester), isFalse);

    // Saving on a second try unlocks it.
    shareSaves = true;
    await exportCheckpoint(tester);
    expect(fieldEnabled(tester), isTrue);
  });

  testWidgets('Delete stays disabled until the phrase is typed', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tapReset(tester);
    await exportCheckpoint(tester);

    await type(tester, 'delete my');
    expect(deleteButton(tester).onPressed, isNull);

    await type(tester, 'Delete my data ');
    expect(deleteButton(tester).onPressed, isNotNull);

    await type(tester, 'delete my data!');
    expect(deleteButton(tester).onPressed, isNull);

    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    expect(resetter.resets, 0, reason: 'a disabled button does nothing');
  });

  testWidgets(
    'exporting, typing the phrase and confirming deletes everything',
    (tester) async {
      await pumpProfile(tester);
      await tapReset(tester);
      await exportCheckpoint(tester);

      await type(tester, 'delete my data');
      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();

      expect(resetter.resets, 1);
      expect(find.text('All data deleted'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('Cancel deletes nothing, even after exporting and typing', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tapReset(tester);
    await exportCheckpoint(tester);

    await type(tester, 'delete my data');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resetter.resets, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('reopening the dialog needs a new checkpoint', (tester) async {
    await pumpProfile(tester);
    await tapReset(tester);
    await exportCheckpoint(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tapReset(tester);

    expect(find.text('Export checkpoint'), findsOneWidget);
    expect(fieldEnabled(tester), isFalse);
  });

  testWidgets('a failed reset says nothing changed', (tester) async {
    resetter.fail = true;
    await pumpProfile(tester);
    await tapReset(tester);
    await exportCheckpoint(tester);

    await type(tester, 'delete my data');
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your data could not be deleted. Nothing was changed.'),
      findsOneWidget,
    );
    expect(find.text('Deleting your data…'), findsNothing);
  });

  testWidgets('reset is blocked while signed in and deletes nothing', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      auth: FakeAuthRepository(
        initial: const SignedIn(
          userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
          email: 'a@test.com',
        ),
      ),
    );

    await tapReset(tester);

    expect(find.text('Reset is not available while signed in'), findsOneWidget);
    expect(find.text('Delete all your data?'), findsNothing);
    expect(resetter.resets, 0);
  });
}
