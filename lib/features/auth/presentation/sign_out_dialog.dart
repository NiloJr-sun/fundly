import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_store.dart';

/// Asks before signing out; returns true to sign out.
///
/// While changes wait to upload, it warns instead (cloud sync S5.5): signing
/// out keeps them on this device until the next sign-in here, so other
/// devices will not see them until then. The count is live; once it reaches
/// zero the dialog becomes the usual confirmation. It never signs out by
/// itself and never discards anything.
class SignOutDialog extends ConsumerWidget {
  const SignOutDialog({super.key, this.isWeb = kIsWeb});

  /// On web the waiting changes live only in this browser's storage.
  final bool isWeb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingUploadCountProvider).value ?? 0;
    final stuck =
        ref.watch(syncStateProvider).value?.connection == SyncConnection.stuck;
    final theme = Theme.of(context);
    if (pending == 0) {
      return AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will return to the login page. Your signed-in data stays on '
          'this device and returns when you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(
        pending == 1
            ? "1 change hasn't uploaded yet"
            : "$pending changes haven't uploaded yet",
      ),
      content: Text(
        [
          'If you sign out now, ${pending == 1 ? 'it stays' : 'they stay'} on '
              'this device and ${pending == 1 ? 'uploads' : 'upload'} the next '
              'time you sign in here with this account. Your other devices '
              "won't see ${pending == 1 ? 'it' : 'them'} until then.",
          if (stuck)
            "Sync is stuck: a change can't upload until the app or server is "
                'updated.',
          if (isWeb)
            "Clearing this browser's site data deletes changes that haven't "
                'uploaded.',
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign out anyway'),
        ),
      ],
    );
  }
}
