import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';

/// Shown instead of export or restore while signed in, until backups of
/// synchronized data are designed (S6).
const signedInBackupMessage =
    'Backups of signed-in data are not available yet. Sign out to back up '
    'or restore the data on this device.';

/// Whether this device's data can be backed up. Signed in, records live in the
/// synchronized store, which needs the UUID backup format (cloud sync S6), so
/// this explains why and returns false.
bool canBackUpOrExplain(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(authIdentityProvider) is! SignedIn) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text(signedInBackupMessage)));
  return false;
}
