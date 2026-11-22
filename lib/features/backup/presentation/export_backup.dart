import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/backup_exporter.dart';
import 'signed_in_backup.dart';

/// Hands a backup file to the platform, e.g. the iOS share sheet, and returns
/// whether the user saved or sent it. [origin] anchors the share sheet on iPad.
typedef ShareBackupFile = Future<bool> Function(
  BackupFile file, {
  Rect? origin,
});

/// Shares through the system share sheet (Save to Files, AirDrop, Mail…).
/// Override it in tests so they never open the real sheet.
final shareBackupFileProvider = Provider<ShareBackupFile>(
  (ref) => _shareWithSystemSheet,
);

Future<bool> _shareWithSystemSheet(BackupFile file, {Rect? origin}) async {
  final result = await SharePlus.instance.share(
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
  return wasShared(result.status, isWeb: kIsWeb);
}

/// Whether a share sheet [status] means the file was saved or sent: the user
/// chose an action. Closing the sheet does not count. A browser downloads the
/// file and cannot say whether it was kept, so there "unavailable" counts as
/// saved.
bool wasShared(ShareResultStatus status, {required bool isWeb}) =>
    switch (status) {
      ShareResultStatus.success => true,
      ShareResultStatus.dismissed => false,
      ShareResultStatus.unavailable => isWeb,
    };

/// Builds a JSON backup and opens the share sheet for it. Shows a progress
/// dialog while preparing and a snackbar if anything fails. Closing the share
/// sheet without choosing anything is not an error.
///
/// Returns whether the file was saved or sent (see [wasShared]). [kind] only
/// changes the file name. [origin] is the widget the share sheet points at on
/// iPad.
Future<bool> exportBackup(
  BuildContext context,
  WidgetRef ref, {
  BackupFileKind kind = BackupFileKind.backup,
  Rect? origin,
}) async {
  if (!await canBackUpOrExplain(context, ref) || !context.mounted) {
    return false;
  }
  final signedIn = ref.read(authIdentityProvider) is SignedIn;
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
    file = await ref.read(backupExporterProvider).createFile(kind: kind);
  } on Object {
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('The backup could not be created.')),
    );
    return false;
  }
  navigator.pop();

  try {
    final saved = await ref.read(shareBackupFileProvider)(file, origin: origin);
    if (saved && signedIn) {
      messenger.showSnackBar(
        const SnackBar(content: Text(signedInBackupSavedMessage)),
      );
    }
    return saved;
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('The backup could not be shared.')),
    );
    return false;
  }
}
