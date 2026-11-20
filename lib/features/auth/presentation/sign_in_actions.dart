import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_identity.dart';

/// Signs in with Google. On success the app switches to the user's own
/// database (and rebuilds from the home tabs); on failure a message is shown
/// and nothing changes. Cancelling says nothing.
Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  } on SignInCancelled {
    return;
  } on SignInFailed catch (failure) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not sign in. ${failure.message}')),
    );
  }
}

/// Asks for confirmation, then signs out on this device. The signed-in
/// user's data stays on the device and reopens on the next sign-in.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'Fundly will switch back to the data on this device that is not '
        'linked to an account. Your signed-in data stays on this device and '
        'returns when you sign in again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(authRepositoryProvider).signOut();
}
