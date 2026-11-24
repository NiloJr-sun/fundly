import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/active_space.dart';
import '../data/space_directory.dart';
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

/// The active space's name when the user has more than one space, so screens
/// say which finances they show; null with only Personal (screens then look
/// exactly as before spaces, Decision C2-7).
final shownSpaceNameProvider = Provider<String?>((ref) {
  final spaces = ref.watch(spacesProvider).value ?? const [];
  if (spaces.length < 2) return null;
  return ref.watch(activeSpaceProvider)?.name;
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
