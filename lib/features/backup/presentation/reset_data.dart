import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/backup_importer.dart';
import '../data/data_resetter.dart';
import 'export_backup.dart';
import 'restore_backup.dart';

/// What the user types to confirm a reset.
const resetConfirmationPhrase = 'delete my data';

/// Whether [typed] confirms a reset: [resetConfirmationPhrase], ignoring
/// capitals and spaces at either end.
bool confirmsReset(String typed) =>
    typed.trim().toLowerCase() == resetConfirmationPhrase;

/// Resetting signed-in (cloud) data would delete it on every device, which
/// needs the server-side replace planned for cloud sync S6. Until then it only
/// works signed out.
Future<void> _explainResetUnavailable(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Reset is not available while signed in'),
    content: const Text(
      'Resetting deletes all data. To reset, sign out first: the reset '
      'then deletes the data on this device that is not linked to an '
      'account.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('OK'),
      ),
    ],
  ),
);

/// Shows what will be deleted, offers to export first, and asks the user to
/// type [resetConfirmationPhrase] before deleting every record on this device.
/// The default categories come back, as on a fresh install.
///
/// Nothing changes unless the user confirms. [origin] is where the export
/// share sheet points on iPad.
Future<void> resetData(
  BuildContext context,
  WidgetRef ref, {
  Rect? origin,
}) async {
  if (ref.read(authIdentityProvider) is SignedIn) {
    await _explainResetUnavailable(context);
    return;
  }

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

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmResetDialog(
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
              Expanded(child: Text('Deleting your data…')),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    await ref.read(dataResetterProvider).resetAll();
  } on Object {
    navigator.pop();
    tell('Your data could not be deleted. Nothing was changed.');
    return;
  }
  navigator.pop();
  tell('All data deleted');
}

class _ConfirmResetDialog extends StatefulWidget {
  const _ConfirmResetDialog({
    required this.current,
    required this.onExportFirst,
  });

  final BackupCounts current;
  final Future<void> Function(BuildContext context) onExportFirst;

  @override
  State<_ConfirmResetDialog> createState() => _ConfirmResetDialogState();
}

class _ConfirmResetDialogState extends State<_ConfirmResetDialog> {
  final _controller = TextEditingController();
  var _confirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Delete all your data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'On this phone now',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(describeCounts(widget.current)),
            const SizedBox(height: Spacing.md),
            const Text(
              'Everything on this phone is deleted and Fundly starts fresh '
              "with its default categories. This can't be undone.",
            ),
            const SizedBox(height: Spacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.ios_share),
                label: const Text('Export backup first'),
                onPressed: () => widget.onExportFirst(context),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Text('Type "$resetConfirmationPhrase" to confirm.'),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                hintText: resetConfirmationPhrase,
                border: OutlineInputBorder(),
              ),
              onChanged: (text) =>
                  setState(() => _confirmed = confirmsReset(text)),
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
          onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}
