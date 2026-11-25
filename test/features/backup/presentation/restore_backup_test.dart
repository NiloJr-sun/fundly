import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';
import 'package:fundly/features/backup/presentation/restore_backup.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';

import '../../../helpers/provider_overrides.dart';

/// Parses for real (no database needed) and records restores.
class FakeBackupImporter implements BackupImporter {
  final List<BackupSnapshot> restored = [];
  bool failRestore = false;

  @override
  BackupSnapshot parse(String contents) => parseBackup(contents);

  @override
  Future<BackupCounts> currentCounts() async => const BackupCounts(
    customAccountTypes: 0,
    accounts: 6,
    categories: 9,
    transactions: 131,
    monthlyPlans: 2,
    customBanks: 0,
  );

  @override
  Future<void> replaceAll(BackupSnapshot snapshot) async {
    if (failRestore) {
      throw const BackupImportException(
        BackupImportProblem.invalidData,
        'rejected by the database',
      );
    }
    restored.add(snapshot);
  }
}

class FakeBackupExporter implements BackupExporter {
  @override
  Future<BackupFile> createFile({
    BackupFileKind kind = BackupFileKind.backup,
  }) async => const BackupFile(
    fileName: 'fundly-backup-2026-11-17.json',
    contents: '{}',
  );

  @override
  Future<Map<String, Object?>> export() async => const {};
}

/// A valid backup with two accounts and one transaction.
String validBackup() => jsonEncode({
  'app': 'fundly',
  'formatVersion': 2,
  'schemaVersion': 7,
  'exportedAt': '2026-11-17T01:00:00.000Z',
  'customAccountTypes': <Object>[],
  'accounts': [
    for (final (id, name) in [(1, 'BDO Savings'), (2, 'Cash Wallet')])
      {
        'id': id,
        'name': name,
        'type': 'savingsCash',
        'customTypeId': null,
        'openingBalanceMinor': 100000,
        'currencyCode': 'PHP',
        'createdAt': '2026-11-16T09:30:00.000Z',
        'isArchived': false,
      },
  ],
  'categories': <Object>[],
  'transactions': [
    {
      'id': 1,
      'type': 'transfer',
      'amountMinor': 5000,
      'currencyCode': 'PHP',
      'date': '2026-11-16',
      'payee': '',
      'categoryId': null,
      'sourceAccountId': 1,
      'destinationAccountId': 2,
      'note': '',
      'createdAt': '2026-11-16T10:00:00.000Z',
      'updatedAt': '2026-11-16T10:00:00.000Z',
    },
  ],
  'monthlyPlans': <Object>[],
});

void main() {
  late FakeBackupImporter importer;
  late List<BackupFile> shared;
  late String? pickedContents;

  setUp(() {
    importer = FakeBackupImporter();
    shared = [];
    pickedContents = validBackup();
  });

  Future<void> pumpProfileTab(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeAccounts(const []),
          backupImporterProvider.overrideWithValue(importer),
          backupExporterProvider.overrideWithValue(FakeBackupExporter()),
          pickBackupFileProvider.overrideWithValue(() async => pickedContents),
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

  Future<void> tapRestore(WidgetTester tester) async {
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();
  }

  testWidgets('picking no file does nothing', (tester) async {
    pickedContents = null;
    await pumpProfileTab(tester);

    await tapRestore(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(importer.restored, isEmpty);
  });

  testWidgets('an invalid file says why and changes nothing', (tester) async {
    pickedContents = '{"app": "something else"}';
    await pumpProfileTab(tester);

    await tapRestore(tester);

    expect(find.text('This file is not a Fundly backup.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(importer.restored, isEmpty);
  });

  testWidgets('invalid data names the problem', (tester) async {
    pickedContents = validBackup().replaceFirst('"transfer"', '"gift"');
    await pumpProfileTab(tester);

    await tapRestore(tester);

    expect(
      find.textContaining('This backup has invalid data (transactions[0].type'),
      findsOneWidget,
    );
    expect(importer.restored, isEmpty);
  });

  testWidgets('confirms with both counts, then replaces', (tester) async {
    await pumpProfileTab(tester);

    await tapRestore(tester);

    expect(find.text('Replace all your data?'), findsOneWidget);
    expect(find.text('Backup from Nov 17, 2026'), findsOneWidget);
    expect(
      find.text(
        '2 accounts · 0 account types · 0 categories · 1 transaction · '
        '0 plans',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '6 accounts · 0 account types · 9 categories · 131 transactions · '
        '2 plans',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(importer.restored.single.counts.transactions, 1);
    expect(find.text('Backup restored'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Cancel restores nothing', (tester) async {
    await pumpProfileTab(tester);
    await tapRestore(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(importer.restored, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Export current data first shares, then Replace still works', (
    tester,
  ) async {
    await pumpProfileTab(tester);
    await tapRestore(tester);

    await tester.tap(find.text('Export current data first'));
    await tester.pumpAndSettle();

    expect(shared.single.fileName, 'fundly-backup-2026-11-17.json');
    expect(find.text('Replace all your data?'), findsOneWidget, reason: 'open');
    expect(importer.restored, isEmpty);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(importer.restored, hasLength(1));
  });

  testWidgets('a restore the database rejects says nothing changed', (
    tester,
  ) async {
    importer.failRestore = true;
    await pumpProfileTab(tester);
    await tapRestore(tester);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing was changed.'), findsOneWidget);
    expect(find.text('Restoring backup…'), findsNothing);
  });
}
