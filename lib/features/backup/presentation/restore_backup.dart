import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/backup_importer.dart';
import 'copy_device_data_screen.dart';
import 'export_backup.dart';

/// Lets the user pick a backup file and returns its text, or `null` if they
/// picked nothing. Override it in tests so they never open the real picker.
typedef PickBackupFile = Future<String?> Function();

final pickBackupFileProvider = Provider<PickBackupFile>(
  (ref) => _pickWithFilesApp,
);

Future<String?> _pickWithFilesApp() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  if (file == null) return null;
  return utf8.decode(await file.readAsBytes());
}

/// Restore replaces all data, and doing that to a signed-in (cloud) dataset
/// needs its own design (cloud sync S6). Until then it only works signed out.
/// Picks a backup, checks it, asks the user to confirm replacing all data
/// (offering to export the current data first), then restores it.
///
/// Signed in, the checked backup goes to the account instead, through the
/// same screen that copies this device's data (cloud sync S6.3).
///
/// Nothing changes unless the file is valid and the user chooses Replace.
/// [origin] is where the export share sheet points on iPad.
Future<void> restoreBackup(
  BuildContext context,
  WidgetRef ref, {
  Rect? origin,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void tell(String message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));

  final String? contents;
  try {
    contents = await ref.read(pickBackupFileProvider)();
  } on Object {
    tell('The file could not be opened.');
    return;
  }
  if (contents == null || !context.mounted) return;

  if (ref.read(authIdentityProvider) is SignedIn) {
    final BackupSnapshot snapshot;
    try {
      snapshot = parseBackup(contents);
    } on BackupImportException catch (exception) {
      tell(backupImportErrorText(exception));
      return;
    } on Object {
      tell('The backup could not be read.');
      return;
    }
    await openRestoreToAccount(context, snapshot);
    return;
  }

  final importer = ref.read(backupImporterProvider);
  final BackupSnapshot snapshot;
  final BackupCounts current;
  try {
    snapshot = importer.parse(contents);
    current = await importer.currentCounts();
  } on BackupImportException catch (exception) {
    tell(backupImportErrorText(exception));
    return;
  } on Object {
    tell('The backup could not be read.');
    return;
  }
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmRestoreDialog(
      snapshot: snapshot,
      current: current,
      onExportFirst: (dialogContext) =>
          exportBackup(dialogContext, ref, origin: origin),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final navigator = Navigator.of(context);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: Spacing.lg),
              Expanded(child: Text('Restoring backup…')),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    await importer.replaceAll(snapshot);
  } on BackupImportException catch (exception) {
    navigator.pop();
    tell(backupImportErrorText(exception));
    return;
  } on Object {
    navigator.pop();
    tell('The backup could not be restored. Your data was not changed.');
    return;
  }
  navigator.pop();
  tell('Backup restored');
}

/// What to tell the user when a backup cannot be restored.
String backupImportErrorText(BackupImportException exception) =>
    switch (exception.problem) {
      BackupImportProblem.notABackup => 'This file is not a Fundly backup.',
      BackupImportProblem.newerFormat =>
        'This backup is from a newer version of Fundly. Update the app to '
            'restore it.',
      BackupImportProblem.invalidData =>
        'This backup has invalid data (${exception.detail}). Nothing was '
            'changed.',
    };

class _ConfirmRestoreDialog extends StatelessWidget {
  const _ConfirmRestoreDialog({
    required this.snapshot,
    required this.current,
    required this.onExportFirst,
  });

  final BackupSnapshot snapshot;
  final BackupCounts current;
  final Future<void> Function(BuildContext context) onExportFirst;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Replace all your data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup from ${DateFormatter.localDate(snapshot.exportedAt)}',
              style: textTheme.titleSmall,
            ),
            Text(describeCounts(snapshot.counts)),
            const SizedBox(height: Spacing.md),
            Text('On this phone now', style: textTheme.titleSmall),
            Text(describeCounts(current)),
            const SizedBox(height: Spacing.md),
            const Text(
              "Everything on this phone is replaced by the backup. This can't "
              'be undone.',
            ),
            const SizedBox(height: Spacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.ios_share),
                label: const Text('Export current data first'),
                onPressed: () => onExportFirst(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Replace'),
        ),
      ],
    );
  }
}

/// e.g. `5 accounts · 1 account type · 10 categories · 120 transactions ·
/// 8 plans`.
String describeCounts(BackupCounts counts) {
  String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  return [
    count(counts.accounts, 'account', 'accounts'),
    count(counts.customAccountTypes, 'account type', 'account types'),
    count(counts.categories, 'category', 'categories'),
    count(counts.transactions, 'transaction', 'transactions'),
    count(counts.monthlyPlans, 'plan', 'plans'),
  ].join(' · ');
}
