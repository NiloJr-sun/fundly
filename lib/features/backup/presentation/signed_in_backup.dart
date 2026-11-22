import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';

/// Why a signed-in backup cannot be made right now. Each case means the file
/// might not match the account on the server.
enum SignedInExportBlocker {
  /// The server cannot process a queued change, so later ones wait.
  stuck,

  /// Changes made on this device have not reached the server yet.
  uploadsWaiting,

  /// This device has never finished downloading the account's data.
  notDownloaded,

  /// On the web, some records hold numbers the browser cannot read exactly.
  unreadableRows,
}

/// Whether a signed-in backup can be made from this device's synchronized
/// store now, or why not. `null` means it can.
SignedInExportBlocker? signedInExportBlocker({
  required SyncState state,
  required int pendingUploads,
  required int unsafeRows,
  required bool isWeb,
}) {
  if (state.connection == SyncConnection.stuck) {
    return SignedInExportBlocker.stuck;
  }
  if (pendingUploads > 0) return SignedInExportBlocker.uploadsWaiting;
  if (!state.hasSynced) return SignedInExportBlocker.notDownloaded;
  if (isWeb && unsafeRows > 0) return SignedInExportBlocker.unreadableRows;
  return null;
}

/// What to tell the user when [blocker] stops a signed-in backup.
String signedInExportBlockerText(SignedInExportBlocker blocker) =>
    switch (blocker) {
      SignedInExportBlocker.stuck =>
        'Sync is stuck, so this device may not match your account. Check the '
            'sync status on Profile, then try again.',
      SignedInExportBlocker.uploadsWaiting =>
        'Some changes are still waiting to upload. Try again once they have '
            'synced, so the backup matches your account.',
      SignedInExportBlocker.notDownloaded =>
        "Your data hasn't finished downloading to this device. Try again "
            'once it has synced.',
      SignedInExportBlocker.unreadableRows =>
        "Some records hold numbers this browser can't read exactly. Make the "
            'backup from the phone app instead.',
    };

/// Shown after a signed-in backup is saved: format 7 files cannot be
/// restored until cloud sync S6.3.
const signedInBackupSavedMessage =
    'Backup saved. Backups made while signed in can be restored in a later '
    'update.';

/// Whether this device's data can be backed up now. Signed out it always can.
/// Signed in, the synchronized store must match the server; otherwise this
/// explains why in a snackbar and returns false.
Future<bool> canBackUpOrExplain(BuildContext context, WidgetRef ref) async {
  if (ref.read(authIdentityProvider) is! SignedIn) return true;
  final messenger = ScaffoldMessenger.of(context);
  final SignedInExportBlocker? blocker;
  try {
    blocker = signedInExportBlocker(
      state:
          await ref.read(syncStateProvider.future) ??
          const SyncState(connection: SyncConnection.connecting),
      pendingUploads: await ref.read(pendingUploadCountProvider.future),
      unsafeRows: await ref.read(unsafeSyncedRowCountProvider.future),
      isWeb: kIsWeb,
    );
  } on Object {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text("Your sync status couldn't be read.")),
      );
    return false;
  }
  if (blocker == null) return true;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(signedInExportBlockerText(blocker))));
  return false;
}
