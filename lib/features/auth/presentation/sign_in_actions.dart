import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_identity.dart';
import 'sign_out_dialog.dart';

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

/// Asks for confirmation ([SignOutDialog], which warns about changes still
/// waiting to upload), then signs out on this device and returns to the login
/// page. The signed-in user's data, including waiting changes, stays on the
/// device and reopens on the next sign-in.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const SignOutDialog(),
  );
  if (confirmed != true) return;
  await ref.read(authRepositoryProvider).signOut();
}
