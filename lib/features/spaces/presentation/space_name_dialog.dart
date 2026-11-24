import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_queue.dart' show newRecordId;
import '../data/active_space.dart';
import '../data/space_directory.dart';
import '../data/space_service.dart';
import '../domain/space.dart';
import 'space_providers.dart';

/// Asks for a name and creates a space (online only), then switches to it.
/// Returns the new space, or null when cancelled.
Future<Space?> createSpace(BuildContext context) => showDialog<Space>(
  context: context,
  builder: (_) => const _SpaceNameDialog(),
);

/// Asks for a new name for [space] (owners only, online only).
Future<Space?> renameSpace(BuildContext context, Space space) =>
    showDialog<Space>(
      context: context,
      builder: (_) => _SpaceNameDialog(renaming: space),
    );

class _SpaceNameDialog extends ConsumerStatefulWidget {
  const _SpaceNameDialog({this.renaming});

  final Space? renaming;

  @override
  ConsumerState<_SpaceNameDialog> createState() => _SpaceNameDialogState();
}

class _SpaceNameDialogState extends ConsumerState<_SpaceNameDialog> {
  late final _name = TextEditingController(text: widget.renaming?.name);

  /// Kept for the dialog's life, so retrying after a lost connection cannot
  /// create a second space (the server returns the first).
  final _newId = newRecordId();
  String? _problem;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final spaces = ref.read(spacesProvider).value ?? const [];
    final renaming = widget.renaming;
    final problem = spaceNameProblem(
      _name.text,
      spaces,
      exceptId: renaming?.id,
    );
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    final service = ref.read(spaceServiceProvider);
    if (service == null) {
      setState(() => _problem = 'Spaces are not available in this version');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    final name = _name.text.trim();
    try {
      final space = renaming == null
          ? await service.create(spaceId: _newId, name: name)
          : await service.rename(renaming, name);
      if (renaming == null) {
        await ref.read(activeSpaceIdProvider.notifier).select(space.id);
      }
      if (mounted) Navigator.of(context).pop(space);
    } on SpaceException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = switch (error.problem) {
          SpaceProblem.offline =>
            "Couldn't reach the server. "
                '${renaming == null ? 'Creating' : 'Renaming'} a space needs '
                'a connection.',
          SpaceProblem.invalidName => 'Use 1 to 40 characters',
          SpaceProblem.nameTaken => 'You already have a space called $name',
          SpaceProblem.limitReached => 'You can have up to 10 spaces',
          SpaceProblem.changed =>
            'This space was just changed on another device. Try again in a '
                'moment.',
          SpaceProblem.refused => 'Only the owner can rename this space',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final renaming = widget.renaming;
    return AlertDialog(
      title: Text(renaming == null ? 'New space' : 'Rename space'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (renaming == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'A separate set of accounts, categories and plans, with its '
                'own default categories.',
              ),
            ),
          TextField(
            controller: _name,
            autofocus: true,
            enabled: !_busy,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: renaming == null ? 'e.g. Business' : null,
              errorText: _problem,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _busy ? null : _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(renaming == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
