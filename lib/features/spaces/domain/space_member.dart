import 'package:flutter/foundation.dart';

import 'space.dart';

/// Someone who belongs to a space (shared spaces C3). Members see each
/// other's email and name as signed in when they joined (Decision C3-3),
/// nothing else about each other.
@immutable
final class SpaceMember {
  const SpaceMember({
    required this.userId,
    required this.role,
    this.email,
    this.displayName,
  });

  final String userId;
  final SpaceRole role;

  /// Null only when the sign-in had none.
  final String? email;
  final String? displayName;

  /// The name to show: the display name, else the email, else "Member".
  String get label => switch ((displayName?.trim(), email?.trim())) {
    (final String name, _) when name.isNotEmpty => name,
    (_, final String address) when address.isNotEmpty => address,
    _ => 'Member',
  };

  @override
  bool operator ==(Object other) =>
      other is SpaceMember &&
      other.userId == userId &&
      other.role == role &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(userId, role, email, displayName);
}

/// Members in the order the Members screen shows them: owners, editors,
/// then viewers, each by name ignoring case.
List<SpaceMember> sortedMembers(Iterable<SpaceMember> members) =>
    [...members]..sort((a, b) {
      final byRole = a.role.index.compareTo(b.role.index);
      if (byRole != 0) return byRole;
      final byName = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      return byName != 0 ? byName : a.userId.compareTo(b.userId);
    });
