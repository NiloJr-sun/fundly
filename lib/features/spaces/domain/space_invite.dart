import 'package:flutter/foundation.dart';

import 'space.dart';

/// The roles an invite can give (an owner promotes members afterwards).
const inviteRoles = [SpaceRole.editor, SpaceRole.viewer];

/// A pending invite, as its space's owners see it (shared spaces C3). The
/// secret is never listed: only the owner who created it got it, once.
@immutable
final class SpaceInvite {
  const SpaceInvite({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String email;
  final SpaceRole role;
  final DateTime createdAt;
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      other is SpaceInvite &&
      other.id == id &&
      other.email == email &&
      other.role == role &&
      other.createdAt == createdAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(id, email, role, createdAt, expiresAt);
}

/// An invite just created, with the secret its link carries. Shown once:
/// the server keeps only the secret's hash.
@immutable
final class CreatedInvite {
  const CreatedInvite({
    required this.id,
    required this.secret,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  final String id;
  final String secret;
  final String email;
  final SpaceRole role;
  final DateTime expiresAt;
}

/// What an invite offers, shown to the email it names before accepting.
@immutable
final class InvitePreview {
  const InvitePreview({
    required this.spaceId,
    required this.spaceName,
    required this.role,
    required this.expiresAt,
    required this.alreadyMember,
    this.inviterName,
    this.inviterEmail,
  });

  final String spaceId;
  final String spaceName;
  final SpaceRole role;
  final DateTime expiresAt;

  /// The user already belongs to the space; accepting keeps their role.
  final bool alreadyMember;
  final String? inviterName;
  final String? inviterEmail;

  /// Who invited, by name, else email, else null.
  String? get inviterLabel =>
      switch ((inviterName?.trim(), inviterEmail?.trim())) {
        (final String name, _) when name.isNotEmpty => name,
        (_, final String address) when address.isNotEmpty => address,
        _ => null,
      };
}

/// The space an accepted invite joined, and the role the user has there.
@immutable
final class JoinedSpace {
  const JoinedSpace({
    required this.spaceId,
    required this.spaceName,
    required this.role,
  });

  final String spaceId;
  final String spaceName;
  final SpaceRole role;
}

/// What an invite email must be, as the server checks it: trimmed, at most
/// 254 characters, something before and after one `@`. Returns the problem,
/// or null when [email] is fine. [memberEmails] are the space's members, who
/// cannot be invited again.
String? inviteEmailProblem(String email, Iterable<String?> memberEmails) {
  final normalized = normalizeInviteEmail(email);
  if (normalized.isEmpty) return 'Enter an email';
  if (normalized.length > 254 || !_emailShape.hasMatch(normalized)) {
    return 'Enter a valid email';
  }
  if (memberEmails.any((member) => member?.toLowerCase() == normalized)) {
    return 'Already a member of this space';
  }
  return null;
}

/// [email] as the server stores it: trimmed and lower-cased.
String normalizeInviteEmail(String email) => email.trim().toLowerCase();

/// The server's `like '%_@_%'`, with no spaces inside.
final _emailShape = RegExp(r'^[^\s@]+@[^\s@]+$');
