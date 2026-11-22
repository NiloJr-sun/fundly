import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_store.dart';

/// Shown instead of a form while signed-in data is view-only (S5.2).
const readOnlyMessage =
    'Editing arrives with sync uploads. Signed-in data is view-only for now.';

/// Shown instead of export or restore while signed in, until backups of
/// synchronized data are designed (S6).
const signedInBackupMessage =
    'Backups of signed-in data are not available yet. Sign out to back up '
    'or restore the data on this device.';

/// Whether records can be changed. If not, explains why and returns false, so
/// an entry point can stop before opening a form.
bool canEditOrExplain(
  BuildContext context, {
  String message = readOnlyMessage,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(canEditProvider)) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  return false;
}
