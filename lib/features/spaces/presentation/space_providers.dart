import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/active_space.dart';
import '../data/space_directory.dart';
import '../data/space_removals.dart';
import '../domain/space.dart';

/// The active space as listed, or null before the list has downloaded.
final activeSpaceProvider = Provider<Space?>((ref) {
  final id = ref.watch(activeSpaceIdProvider);
  final spaces = ref.watch(spacesProvider).value ?? const [];
  for (final space in spaces) {
    if (space.id == id) return space;
  }
  return null;
});

/// Whether the active space is one that left the user and is kept on this
/// device only to review its changes (shared spaces C3).
final activeSpaceRemovedProvider = Provider<bool>((ref) {
  final id = ref.watch(activeSpaceIdProvider);
  return id != null && ref.watch(spaceRemovalsProvider).isRemoved(id);
});

/// Whether the user may change the records on screen (shared spaces C3,
/// Decision C3-8). Every add, edit, delete and archive entry point checks it
/// and shows a "View only" note instead of a form when false; the server
/// refuses such changes anyway.
///
/// Always true signed out and in Personal. In another space, true for an
/// owner or editor; false for a viewer, for a space that left the user, and
/// before the spaces list has downloaded.
final canEditProvider = Provider<bool>((ref) {
  final userId = ref.watch(
    authIdentityProvider.select(
      (identity) => identity is SignedIn ? identity.userId : null,
    ),
  );
  if (userId == null) return true;
  final activeId = ref.watch(activeSpaceIdProvider);
  if (activeId == null || activeId == userId) return true;
  if (ref.watch(activeSpaceRemovedProvider)) return false;
  final role = ref.watch(activeSpaceProvider)?.role;
  return role == SpaceRole.owner || role == SpaceRole.editor;
});

/// The active space's name when the user has more than one space, so screens
/// say which finances they show; null with only Personal (screens then look
/// exactly as before spaces, Decision C2-7).
/// Used in sentences ("Delete every record in Household"), so it is the name
/// alone; [shownSpaceTitleProvider] adds the role for titles.
final shownSpaceNameProvider = Provider<String?>((ref) {
  final spaces = ref.watch(spacesProvider).value ?? const [];
  if (spaces.length < 2) return null;
  return ref.watch(activeSpaceProvider)?.name;
});

/// The line under a tab's title: [shownSpaceNameProvider], followed by the
/// role in a space the user does not own ("Household · Viewer", shared spaces
/// C3), so editors and viewers see what they can do.
final shownSpaceTitleProvider = Provider<String?>((ref) {
  final name = ref.watch(shownSpaceNameProvider);
  final role = ref.watch(activeSpaceProvider)?.role;
  if (name == null || role == null || role == SpaceRole.owner) return name;
  return '$name · ${roleLabel(role)}';
});

/// What a space name must be (the server's rule; Decision C2-6): trimmed,
/// 1 to 40 characters (UTF-16 units, as Dart counts them), and not the name
/// of another space the user owns, ignoring case. Returns the problem, or
/// null when [name] is fine.
String? spaceNameProblem(
  String name,
  Iterable<Space> spaces, {
  String? exceptId,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Enter a name';
  if (trimmed.length > 40) return 'Use 40 characters or fewer';
  final key = _foldAscii(trimmed);
  for (final space in spaces) {
    if (space.id != exceptId &&
        space.role == SpaceRole.owner &&
        _foldAscii(space.name) == key) {
      return 'You already have a space called ${space.name}';
    }
  }
  return null;
}

/// Lower-cases A-Z only, like the server (SQLite NOCASE).
String _foldAscii(String value) => String.fromCharCodes(
  value.codeUnits.map((unit) => unit >= 65 && unit <= 90 ? unit + 32 : unit),
);

/// "Owner", "Editor" or "Viewer".
String roleLabel(SpaceRole role) => switch (role) {
  SpaceRole.owner => 'Owner',
  SpaceRole.editor => 'Editor',
  SpaceRole.viewer => 'Viewer',
};
