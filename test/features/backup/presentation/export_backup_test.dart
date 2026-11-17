import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';

import '../../../helpers/provider_overrides.dart';

/// Returns a fixed file, or throws when [fail] is set.
class FakeBackupExporter implements BackupExporter {
  bool fail = false;

  @override
  Future<BackupFile> createFile() async {
    if (fail) throw Exception('disk error');
    return const BackupFile(
      fileName: 'fundly-backup-2026-11-17.json',
      contents: '{"app": "fundly"}\n',
    );
  }

  @override
  Future<Map<String, Object?>> export() async => const {};
}

void main() {
  late FakeBackupExporter exporter;
  late List<BackupFile> shared;
  late bool shareFails;

  setUp(() {
    exporter = FakeBackupExporter();
    shared = [];
    shareFails = false;
  });

  Future<void> pumpAccountTab(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeAccounts(const []),
          backupExporterProvider.overrideWithValue(exporter),
          shareBackupFileProvider.overrideWithValue((file, {origin}) async {
            if (shareFails) throw Exception('share failed');
            shared.add(file);
          }),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapExport(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
  }

  testWidgets('Export backup shares the JSON file', (tester) async {
    await pumpAccountTab(tester);

    await tapExport(tester);

    expect(shared, hasLength(1));
    expect(shared.single.fileName, 'fundly-backup-2026-11-17.json');
    expect(shared.single.contents, '{"app": "fundly"}\n');
    expect(find.text('Preparing backup…'), findsNothing, reason: 'closed');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed export shows a message and shares nothing', (
    tester,
  ) async {
    exporter.fail = true;
    await pumpAccountTab(tester);

    await tapExport(tester);

    expect(shared, isEmpty);
    expect(find.text('Preparing backup…'), findsNothing);
    expect(find.text('The backup could not be created.'), findsOneWidget);
  });

  testWidgets('a failed share shows a message', (tester) async {
    shareFails = true;
    await pumpAccountTab(tester);

    await tapExport(tester);

    expect(find.text('The backup could not be shared.'), findsOneWidget);
  });
}
