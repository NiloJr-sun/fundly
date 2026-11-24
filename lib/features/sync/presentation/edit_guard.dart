import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../spaces/domain/space.dart';
import '../../spaces/presentation/space_providers.dart';

/// Shown instead of a form to a viewer (shared spaces C3, Decision C3-8).
const viewOnlyMessage = 'View only: your role in this space cannot change it.';

/// Shown instead of a form in a space that left this user (Decision C3-6).
const removedSpaceMessage =
    "You're no longer a member of this space. It is read-only on this device.";

/// Shown instead of a form before the spaces list has downloaded, while the
/// user's role in the active space is not known yet.
const spaceLoadingMessage =
    'This space is still loading. Try again in a moment.';

/// Whether records can be changed ([canEditProvider]). If not, says why and
/// returns false, so an entry point stops before opening a form. The server
/// refuses such changes anyway; this spares the user a refused change.
bool canEditOrExplain(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(canEditProvider)) return true;
  final message = container.read(activeSpaceRemovedProvider)
      ? removedSpaceMessage
      : container.read(activeSpaceProvider)?.role == SpaceRole.viewer
      ? viewOnlyMessage
      : spaceLoadingMessage;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  return false;
}
