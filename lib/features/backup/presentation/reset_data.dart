import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../spaces/presentation/space_providers.dart';
import '../data/backup_exporter.dart';
import '../data/backup_importer.dart';
import '../data/cloud_data_resetter.dart';
import '../data/data_resetter.dart';
import 'checkpoint_confirm_dialog.dart';
import 'export_backup.dart';
import 'signed_in_backup.dart';

/// What the user types to confirm a reset.
const resetConfirmationPhrase = 'delete my data';

/// Whether [typed] confirms a reset: [resetConfirmationPhrase], ignoring
/// capitals and spaces at either end.
bool confirmsReset(String typed) =>
    confirmsPhrase(typed, resetConfirmationPhrase);

/// How long a signed-in reset waits for this device to download the reset
/// account before saying it will catch up later. Overridden in tests.
final resetSyncWaitProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// Shows what will be deleted, requires a reset checkpoint export (see
/// [BackupFileKind.resetCheckpoint]) and asks the user to type
/// [resetConfirmationPhrase] before deleting every record. The default
/// categories come back, as on a fresh install.
///
/// Signed out, this deletes the data on this device. Signed in, it deletes
/// the account's data on the server, so every signed-in device loses it.
///
/// Nothing changes unless the user confirms. [origin] is where the export
/// share sheet points on iPad.
Future<void> resetData(
  BuildContext context,
  WidgetRef ref, {
  Rect? origin,
}) async {
  final identity = ref.read(authIdentityProvider);
  if (identity is SignedIn) {
    await _resetAccount(context, ref, identity, origin: origin);
  } else {
    await _resetDevice(context, ref, origin: origin);
  }
}

Future<void> _resetDevice(
  BuildContext context,
  WidgetRef ref, {
  Rect? origin,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void tell(String message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));

  final BackupCounts current;
  try {
    current = await ref.read(backupImporterProvider).currentCounts();
  } on Object {
    tell('Your data could not be read. Nothing was deleted.');
    return;
  }
  if (!context.mounted) return;

  final confirmed = await _confirm(
    context,
    ref,
    current: current,
    heading: 'On this phone now',
    consequence:
        'Everything on this phone is deleted and Fundly starts fresh with '
        "its default categories. This can't be undone.",
    origin: origin,
  );
  if (!confirmed || !context.mounted) return;

  final done = _showProgress(context);
  try {
    await ref.read(dataResetterProvider).resetAll();
  } on Object {
    done();
    tell('Your data could not be deleted. Nothing was changed.');
    return;
  }
  done();
  tell('All data deleted');
}

Future<void> _resetAccount(
  BuildContext context,
  WidgetRef ref,
  SignedIn identity, {
  Rect? origin,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void tell(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  final store = ref.read(syncedStoreProvider);
  final resetter = ref.read(cloudDataResetterProvider);
  // Reset acts on the active space (shared spaces C2, Decision C2-8).
  final space = ref.read(shownSpaceNameProvider);
  if (store == null || resetter == null) {
    tell('Resetting your account is not available in this version.');
    return;
  }

  final BackupCounts current;
  try {
    final blocked = await _accountResetBlockerText(ref);
    if (blocked != null) {
      tell(blocked);
      return;
    }
    current = await watchSyncedCounts(store.database).first;
  } on Object {
    tell('Your data could not be read. Nothing was deleted.');
    return;
  }
  if (!context.mounted) return;

  final confirmed = await _confirm(
    context,
    ref,
    current: current,
    heading: 'In ${space ?? 'your account'}',
    consequence:
        'Everything in ${space ?? 'your account'} is deleted on every device '
        'signed in as '
        '${identity.email}, and Fundly starts fresh with its default '
        "categories. This can't be undone.",
    origin: origin,
  );
  if (!confirmed || !context.mounted) return;

  // Things may have changed while the dialog was open.
  final String? blocked;
  try {
    blocked = await _accountResetBlockerText(ref);
  } on Object {
    tell('Your data could not be read. Nothing was deleted.');
    return;
  }
  if (blocked != null) {
    tell(blocked);
    return;
  }
  if (!context.mounted) return;

  final wait = ref.read(resetSyncWaitProvider);
  final done = _showProgress(context);
  final BackupCounts after;
  try {
    after = await resetter.resetAll(expected: current);
  } on CloudResetException catch (exception) {
    done();
    tell(cloudResetErrorText(exception));
    return;
  }

  // The server is done; wait for this device to download the result.
  try {
    await watchSyncedCounts(store.database)
        .firstWhere((counts) => counts == after)
        .timeout(wait);
  } on Object {
    done();
    tell('Deleted. This phone will show it after it syncs.');
    return;
  }
  done();
  tell('All data deleted');
}

/// Why the signed-in account cannot be reset right now, or `null`.
Future<String?> _accountResetBlockerText(WidgetRef ref) =>
    signedInServerBlockerText(
      ref,
      offline: "You're offline. Connect to the internet to reset your account.",
    );

/// What to tell the user when a signed-in reset does not finish.
String cloudResetErrorText(CloudResetException exception) =>
    switch (exception.problem) {
      CloudResetProblem.datasetChanged =>
        'Your data changed on another device, so nothing was deleted. Reset '
            'again to see the new counts.',
      CloudResetProblem.unreachable =>
        "Couldn't reach the server. If the reset went through, this phone "
            'will show it after it syncs.',
      CloudResetProblem.refused =>
        'The reset was refused (${exception.code}). Nothing was changed.',
    };

Future<bool> _confirm(
  BuildContext context,
  WidgetRef ref, {
  required BackupCounts current,
  required String heading,
  required String consequence,
  Rect? origin,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => CheckpointConfirmDialog(
        title: 'Delete all your data?',
        current: current,
        heading: heading,
        consequence: consequence,
        phrase: resetConfirmationPhrase,
        confirmLabel: 'Delete everything',
        exportCheckpoint: (dialogContext) => exportBackup(
          dialogContext,
          ref,
          kind: BackupFileKind.resetCheckpoint,
          origin: origin,
        ),
      ),
    ) ==
    true;

/// Shows a blocking "Deleting your data…" dialog; call the result to close it.
void Function() _showProgress(BuildContext context) {
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
              Expanded(child: Text('Deleting your data…')),
            ],
          ),
        ),
      ),
    ),
  );
  return navigator.pop;
}
