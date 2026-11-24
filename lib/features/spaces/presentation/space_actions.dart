import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sharing_service.dart';
import '../domain/space.dart';
import 'invite_dialog.dart';
import 'members_screen.dart';
import 'sharing_messages.dart';
import 'space_name_dialog.dart';

enum _SpaceAction { members, invite, rename, leave, delete }

/// What [space]'s ⋮ menu offers (shared spaces C3): Personal only Rename
/// (it is never shared, left or deleted); in another space everyone sees
/// Members and Leave, owners also Invite, Rename and Delete.
List<_SpaceAction> _actionsFor(Space space) {
  final owner = space.role == SpaceRole.owner;
  if (space.isPersonal) return [if (owner) _SpaceAction.rename];
  return [
    _SpaceAction.members,
    if (owner) _SpaceAction.invite,
    if (owner) _SpaceAction.rename,
    _SpaceAction.leave,
    if (owner) _SpaceAction.delete,
  ];
}

/// The ⋮ button on a space's row in the space sheet.
class SpaceActionsButton extends StatelessWidget {
  const SpaceActionsButton({super.key, required this.space});

  final Space space;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(space);
    if (actions.isEmpty) return const SizedBox.shrink();
    final errorColor = Theme.of(context).colorScheme.error;
    return PopupMenuButton<_SpaceAction>(
      tooltip: 'Actions for ${space.name}',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: switch (action) {
              _SpaceAction.members => const Text('Members'),
              _SpaceAction.invite => const Text('Invite'),
              _SpaceAction.rename => const Text('Rename'),
              _SpaceAction.leave => const Text('Leave space'),
              _SpaceAction.delete => Text(
                'Delete space',
                style: TextStyle(color: errorColor),
              ),
            },
          ),
      ],
    );
  }

  Future<void> _run(BuildContext context, _SpaceAction action) async {
    switch (action) {
      case _SpaceAction.members:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MembersScreen(spaceId: space.id),
          ),
        );
      case _SpaceAction.invite:
        await inviteToSpace(context, space);
      case _SpaceAction.rename:
        await renameSpace(context, space);
      case _SpaceAction.leave:
        await _confirmAndClose(context, _LeaveSpaceDialog(space: space));
      case _SpaceAction.delete:
        await _confirmAndClose(context, _DeleteSpaceDialog(space: space));
    }
  }

  /// Leaving or deleting takes the space off this device (SpaceRemovals does
  /// that once the server's list no longer has it), so the sheet closes.
  Future<void> _confirmAndClose(BuildContext context, Widget dialog) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = await showDialog<String>(
      context: context,
      builder: (_) => dialog,
    );
    if (done == null) return;
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }
}

/// Runs [call] with the sharing service, showing a progress state and the
/// server's refusal in plain words. Pops the dialog with [doneMessage].
mixin _SharingCall<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? problem;

  Future<void> runSharing(
    Future<void> Function(SharingService service) call,
    String doneMessage,
  ) async {
    final service = ref.read(sharingServiceProvider);
    if (service == null) {
      setState(() => problem = 'Sharing is not available in this version');
      return;
    }
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      await call(service);
      if (mounted) Navigator.of(context).pop(doneMessage);
    } on SharingException catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        problem = sharingProblemMessage(error.problem);
      });
    }
  }

  Widget busyLabel(String label) => busy
      ? const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(label);
}

class _LeaveSpaceDialog extends ConsumerStatefulWidget {
  const _LeaveSpaceDialog({required this.space});

  final Space space;

  @override
  ConsumerState<_LeaveSpaceDialog> createState() => _LeaveSpaceDialogState();
}

class _LeaveSpaceDialogState extends ConsumerState<_LeaveSpaceDialog>
    with _SharingCall {
  @override
  Widget build(BuildContext context) {
    final space = widget.space;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Leave ${space.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "You'll no longer see its records, and it leaves this device. "
            'An owner can invite you again. Needs a connection.',
          ),
          if (problem case final problem?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                problem,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () => runSharing(
                  (service) => service.leaveSpace(space.id),
                  'You left ${space.name}.',
                ),
          child: busyLabel('Leave'),
        ),
      ],
    );
  }
}

class _DeleteSpaceDialog extends ConsumerStatefulWidget {
  const _DeleteSpaceDialog({required this.space});

  final Space space;

  @override
  ConsumerState<_DeleteSpaceDialog> createState() => _DeleteSpaceDialogState();
}

class _DeleteSpaceDialogState extends ConsumerState<_DeleteSpaceDialog>
    with _SharingCall {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  /// The server's rule: case and outer spaces ignored.
  bool get _matches =>
      _typed.text.trim().toLowerCase() == widget.space.name.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final space = widget.space;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Delete ${space.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This deletes every account, transaction, category and plan in '
            '${space.name}, for every member, on every device. It cannot be '
            'undone. Export a backup first if you might need them.',
          ),
          const SizedBox(height: 12),
          Text('Type ${space.name} to confirm.'),
          TextField(
            controller: _typed,
            enabled: !busy,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: space.name,
              errorText: problem,
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: busy || !_matches
              ? null
              : () => runSharing(
                  (service) =>
                      service.deleteSpace(spaceId: space.id, name: _typed.text),
                  '${space.name} was deleted.',
                ),
          child: busyLabel('Delete'),
        ),
      ],
    );
  }
}
