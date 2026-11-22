import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/backup_exporter.dart';
import '../data/backup_importer.dart';
import '../data/cloud_data_resetter.dart';
import '../data/data_resetter.dart';
import 'export_backup.dart';
import 'restore_backup.dart';
import 'signed_in_backup.dart';

/// What the user types to confirm a reset.
const resetConfirmationPhrase = 'delete my data';

/// Whether [typed] confirms a reset: [resetConfirmationPhrase], ignoring
/// capitals and spaces at either end.
bool confirmsReset(String typed) =>
    typed.trim().toLowerCase() == resetConfirmationPhrase;

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
    heading: 'In your account',
    consequence:
        'Everything in your account is deleted on every device signed in as '
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

/// Why the signed-in account cannot be reset right now, or `null`. Besides
/// the export checks (the checkpoint must match the account), the reset
/// needs the server.
Future<String?> _accountResetBlockerText(WidgetRef ref) async {
  final state =
      await ref.read(syncStateProvider.future) ??
      const SyncState(connection: SyncConnection.connecting);
  final blocker = signedInExportBlocker(
    state: state,
    pendingUploads: await ref.read(pendingUploadCountProvider.future),
    unsafeRows: await ref.read(unsafeSyncedRowCountProvider.future),
    isWeb: kIsWeb,
  );
  if (blocker != null) return signedInExportBlockerText(blocker);
  if (state.connection != SyncConnection.connected) {
    return "You're offline. Connect to the internet to reset your account.";
  }
  return null;
}

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
      builder: (_) => _ConfirmResetDialog(
        current: current,
        heading: heading,
        consequence: consequence,
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

class _ConfirmResetDialog extends StatefulWidget {
  const _ConfirmResetDialog({
    required this.current,
    required this.heading,
    required this.consequence,
    required this.exportCheckpoint,
  });

  final BackupCounts current;

  /// Where the counts are, e.g. "On this phone now".
  final String heading;

  /// What deleting does, shown below the counts.
  final String consequence;

  /// Exports the checkpoint and returns whether it was saved or sent.
  final Future<bool> Function(BuildContext context) exportCheckpoint;

  @override
  State<_ConfirmResetDialog> createState() => _ConfirmResetDialogState();
}

class _ConfirmResetDialogState extends State<_ConfirmResetDialog> {
  final _controller = TextEditingController();
  var _exported = false;
  var _typed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final saved = await widget.exportCheckpoint(context);
    if (saved && mounted) setState(() => _exported = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AlertDialog(
      title: const Text('Delete all your data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.heading, style: theme.textTheme.titleSmall),
            Text(describeCounts(widget.current)),
            const SizedBox(height: Spacing.md),
            Text(widget.consequence),
            const SizedBox(height: Spacing.md),
            Text('1. Save a checkpoint', style: theme.textTheme.titleSmall),
            const SizedBox(height: Spacing.xs),
            if (_exported)
              Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.primary),
                  const SizedBox(width: Spacing.sm),
                  const Expanded(child: Text('Checkpoint saved')),
                ],
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.ios_share),
                label: const Text('Export checkpoint'),
                onPressed: _export,
              ),
            const SizedBox(height: Spacing.md),
            Text(
              '2. Type "$resetConfirmationPhrase" to confirm',
              style: theme.textTheme.titleSmall?.copyWith(
                color: _exported ? null : theme.disabledColor,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _controller,
              enabled: _exported,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                hintText: resetConfirmationPhrase,
                border: OutlineInputBorder(),
              ),
              onChanged: (text) => setState(() => _typed = confirmsReset(text)),
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
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: _exported && _typed
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}
