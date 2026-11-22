import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/spacing.dart';
import '../../sync/presentation/edit_guard.dart';
import '../data/backup_exporter.dart';

/// Hands a backup file to the platform, e.g. the iOS share sheet.
/// [origin] anchors the share sheet on iPad.
typedef ShareBackupFile = Future<void> Function(
  BackupFile file, {
  Rect? origin,
});

/// Shares through the system share sheet (Save to Files, AirDrop, Mail…).
/// Override it in tests so they never open the real sheet.
final shareBackupFileProvider = Provider<ShareBackupFile>(
  (ref) => _shareWithSystemSheet,
);

Future<void> _shareWithSystemSheet(BackupFile file, {Rect? origin}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(file.contents)),
          mimeType: 'application/json',
          name: file.fileName,
        ),
      ],
      fileNameOverrides: [file.fileName],
      sharePositionOrigin: origin,
    ),
  );
}

/// Builds a JSON backup and opens the share sheet for it. Shows a progress
/// dialog while preparing and a snackbar if anything fails. Closing the share
/// sheet without choosing anything is not an error.
///
/// [origin] is the widget the share sheet points at on iPad.
Future<void> exportBackup(
  BuildContext context,
  WidgetRef ref, {
  Rect? origin,
}) async {
  // Signed in, records are in the synchronized store; backing those up needs
  // the UUID backup format (cloud sync S6).
  if (!canEditOrExplain(context, message: signedInBackupMessage)) return;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  // Closed below once the file is ready; not awaited.
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
              Expanded(child: Text('Preparing backup…')),
            ],
          ),
        ),
      ),
    ),
  );

  BackupFile file;
  try {
    file = await ref.read(backupExporterProvider).createFile();
  } on Object {
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('The backup could not be created.')),
    );
    return;
  }
  navigator.pop();

  try {
    await ref.read(shareBackupFileProvider)(file, origin: origin);
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('The backup could not be shared.')),
    );
  }
}
