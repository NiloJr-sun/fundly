import 'package:flutter/foundation.dart';

/// What a member may do in a space (shared spaces; only owners until C3).
enum SpaceRole {
  owner('owner'),
  editor('editor'),
  viewer('viewer');

  const SpaceRole(this.wireName);

  final String wireName;

  static SpaceRole fromWire(String value) =>
      values.singleWhere((role) => role.wireName == value);
}

/// A space the signed-in user belongs to (shared spaces C2): its own
/// accounts, categories, plans and budget accounts.
@immutable
final class Space {
  const Space({
    required this.id,
    required this.name,
    required this.isPersonal,
    required this.role,
    required this.revision,
  });

  final String id;
  final String name;

  /// The user's own default space; its id is the user's id.
  final bool isPersonal;
  final SpaceRole role;
  final int revision;

  bool get canRename => role == SpaceRole.owner;

  @override
  bool operator ==(Object other) =>
      other is Space &&
      other.id == id &&
      other.name == name &&
      other.isPersonal == isPersonal &&
      other.role == role &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(id, name, isPersonal, role, revision);
}

/// Spaces in the order the switcher shows them: Personal first, then by name
/// ignoring case.
List<Space> sortedSpaces(Iterable<Space> spaces) => [...spaces]
  ..sort((a, b) {
    if (a.isPersonal != b.isPersonal) return a.isPersonal ? -1 : 1;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.id.compareTo(b.id);
  });
