import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../data/backup_importer.dart';
import 'restore_backup.dart' show describeCounts;

/// Whether [typed] is [phrase], ignoring capitals and spaces at either end.
bool confirmsPhrase(String typed, String phrase) =>
    typed.trim().toLowerCase() == phrase;

/// Confirms a step that deletes records: shows what is there now, requires
/// a checkpoint export, then the typed [phrase]. Pops `true` when confirmed.
/// Used by Reset all data and by replacing an account's data with this
/// device's.
class CheckpointConfirmDialog extends StatefulWidget {
  const CheckpointConfirmDialog({
    super.key,
    required this.title,
    required this.heading,
    required this.current,
    required this.consequence,
    required this.phrase,
    required this.confirmLabel,
    required this.exportCheckpoint,
  });

  final String title;

  /// Where the counts are, e.g. "On this phone now".
  final String heading;

  final BackupCounts current;

  /// What confirming does, shown below the counts.
  final String consequence;

  /// What the user types to confirm, in lower case.
  final String phrase;

  /// The destructive button's label.
  final String confirmLabel;

  /// Exports the checkpoint and returns whether it was saved or sent.
  final Future<bool> Function(BuildContext context) exportCheckpoint;

  @override
  State<CheckpointConfirmDialog> createState() =>
      _CheckpointConfirmDialogState();
}

class _CheckpointConfirmDialogState extends State<CheckpointConfirmDialog> {
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
      title: Text(widget.title),
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
              '2. Type "${widget.phrase}" to confirm',
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
              decoration: InputDecoration(
                hintText: widget.phrase,
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) =>
                  setState(() => _typed = confirmsPhrase(text, widget.phrase)),
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
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
