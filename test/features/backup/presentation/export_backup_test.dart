import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/presentation/export_backup.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';
import 'package:share_plus/share_plus.dart' show ShareResultStatus;

import '../../../helpers/provider_overrides.dart';

/// Returns a fixed file, or throws when [fail] is set.
class FakeBackupExporter implements BackupExporter {
  bool fail = false;

  @override
  Future<BackupFile> createFile({
    BackupFileKind kind = BackupFileKind.backup,
  }) async {
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
  group('wasShared', () {
    test('counts a chosen action, not a closed sheet', () {
      expect(wasShared(ShareResultStatus.success, isWeb: false), isTrue);
      expect(wasShared(ShareResultStatus.dismissed, isWeb: false), isFalse);
      expect(wasShared(ShareResultStatus.dismissed, isWeb: true), isFalse);
    });

    test('counts a browser download, which cannot report more', () {
      expect(wasShared(ShareResultStatus.unavailable, isWeb: true), isTrue);
      expect(wasShared(ShareResultStatus.unavailable, isWeb: false), isFalse);
    });
  });

  late FakeBackupExporter exporter;
  late List<BackupFile> shared;
  late bool shareFails;

  setUp(() {
    exporter = FakeBackupExporter();
    shared = [];
    shareFails = false;
  });

  Future<void> pumpProfileTab(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeAccounts(const []),
          backupExporterProvider.overrideWithValue(exporter),
          shareBackupFileProvider.overrideWithValue((file, {origin}) async {
            if (shareFails) throw Exception('share failed');
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

  testWidgets('Export backup shares the JSON file', (tester) async {
    await pumpProfileTab(tester);

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
    await pumpProfileTab(tester);

    await tapExport(tester);

    expect(shared, isEmpty);
    expect(find.text('Preparing backup…'), findsNothing);
    expect(find.text('The backup could not be created.'), findsOneWidget);
  });

  testWidgets('a failed share shows a message', (tester) async {
    shareFails = true;
    await pumpProfileTab(tester);

    await tapExport(tester);

    expect(find.text('The backup could not be shared.'), findsOneWidget);
  });
}
