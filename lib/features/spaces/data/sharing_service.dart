import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/batch_uploader.dart';
import '../domain/space.dart';
import '../domain/space_invite.dart';

/// Why an invite, member or space action did not happen
/// (supabase/SPACES_API.md, Errors).
enum SharingProblem {
  /// No connection, or the server is busy: try again.
  offline,

  /// The user is not (or no longer) a member of the space.
  notMember,
  ownerOnly,

  /// Not allowed for a Personal space (Decision C3-2).
  personalSpace,
  invalidEmail,
  alreadyMember,
  memberLimitReached,
  inviteLimitReached,

  /// The invite is unknown, used, declined, revoked or expired.
  inviteUnavailable,

  /// The invite names another email. Nothing else about it is revealed.
  inviteOtherEmail,
  memberNotFound,

  /// The space would have no owner left (Decision C3-4).
  lastOwner,

  /// Deleting: the typed name does not match the space's.
  nameMismatch,

  /// Anything else the server refused.
  refused,
}

class SharingException implements Exception {
  const SharingException(this.problem, [this.code]);

  final SharingProblem problem;
  final String? code;

  @override
  String toString() => 'SharingException(${problem.name}, $code)';
}

/// Invites, members, leaving and deleting spaces (shared spaces C3), online
/// only (Decision C3-9). Every method throws [SharingException].
abstract interface class SharingService {
  /// Invites [email] to [spaceId] as [role] (editor or viewer; owners only).
  /// A pending invite to the same email is replaced.
  Future<CreatedInvite> createInvite({
    required String spaceId,
    required String email,
    required SpaceRole role,
  });

  /// The space's pending invites, oldest first (owners only).
  Future<List<SpaceInvite>> listInvites(String spaceId);

  Future<void> revokeInvite(String inviteId);

  /// What the invite offers; only for the email it names.
  Future<InvitePreview> previewInvite(String secret);

  Future<JoinedSpace> acceptInvite(String secret);

  Future<void> declineInvite(String secret);

  /// Owners only; a space always keeps an owner.
  Future<void> setMemberRole({
    required String spaceId,
    required String userId,
    required SpaceRole role,
  });

  /// Owners only; not the last owner.
  Future<void> removeMember({required String spaceId, required String userId});

  /// Any member but the last owner.
  Future<void> leaveSpace(String spaceId);

  /// Deletes a non-Personal space for everyone (owners only), once [name]
  /// matches its name (case and outer spaces ignored).
  Future<void> deleteSpace({required String spaceId, required String name});
}

/// The real [SharingService], through [client]'s RPCs.
class SupabaseSharingService implements SharingService {
  SupabaseSharingService(this._client);

  final SupabaseClient _client;

  @override
  Future<CreatedInvite> createInvite({
    required String spaceId,
    required String email,
    required SpaceRole role,
  }) async {
    final result = _object(
      await _call('fundly_create_invite', {
        'space_id': spaceId,
        'email': email,
        'role': role.wireName,
      }),
    );
    return CreatedInvite(
      id: result['invite_id']! as String,
      secret: result['secret']! as String,
      email: result['email']! as String,
      role: SpaceRole.fromWire(result['role']! as String),
      expiresAt: _time(result['expires_at']),
    );
  }

  @override
  Future<List<SpaceInvite>> listInvites(String spaceId) async {
    final rows =
        await _call('fundly_list_invites', {'space_id': spaceId}) as List;
    return [
      for (final row in rows.map(_object))
        SpaceInvite(
          id: row['invite_id']! as String,
          email: row['email']! as String,
          role: SpaceRole.fromWire(row['role']! as String),
          createdAt: _time(row['created_at']),
          expiresAt: _time(row['expires_at']),
        ),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> revokeInvite(String inviteId) =>
      _call('fundly_revoke_invite', {'invite_id': inviteId});

  @override
  Future<InvitePreview> previewInvite(String secret) async {
    final result = _object(
      await _call('fundly_preview_invite', {'secret': secret}),
    );
    return InvitePreview(
      spaceId: result['space_id']! as String,
      spaceName: result['space_name']! as String,
      role: SpaceRole.fromWire(result['role']! as String),
      expiresAt: _time(result['expires_at']),
      alreadyMember: result['already_member']! as bool,
      inviterName: result['inviter_name'] as String?,
      inviterEmail: result['inviter_email'] as String?,
    );
  }

  @override
  Future<JoinedSpace> acceptInvite(String secret) async {
    final result = _object(
      await _call('fundly_accept_invite', {'secret': secret}),
    );
    return JoinedSpace(
      spaceId: result['space_id']! as String,
      spaceName: result['space_name']! as String,
      role: SpaceRole.fromWire(result['role']! as String),
    );
  }

  @override
  Future<void> declineInvite(String secret) =>
      _call('fundly_decline_invite', {'secret': secret});

  @override
  Future<void> setMemberRole({
    required String spaceId,
    required String userId,
    required SpaceRole role,
  }) => _call('fundly_set_member_role', {
    'space_id': spaceId,
    'user_id': userId,
    'role': role.wireName,
  });

  @override
  Future<void> removeMember({
    required String spaceId,
    required String userId,
  }) => _call('fundly_remove_member', {'space_id': spaceId, 'user_id': userId});

  @override
  Future<void> leaveSpace(String spaceId) =>
      _call('fundly_leave_space', {'space_id': spaceId});

  @override
  Future<void> deleteSpace({required String spaceId, required String name}) =>
      _call('fundly_delete_space', {'space_id': spaceId, 'name': name});

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    try {
      return await _client.rpc<dynamic>(function, params: params);
    } on Object catch (error) {
      throw sharingExceptionFor(error);
    }
  }

  static Map<String, Object?> _object(Object? value) =>
      Map<String, Object?>.from(value! as Map);

  static DateTime _time(Object? value) =>
      DateTime.parse(value! as String).toUtc();
}

/// Maps a failed sharing call to its [SharingProblem] (public for tests).
SharingException sharingExceptionFor(Object error) {
  final failure = classifyUploadError(error);
  if (failure.outcome == UploadOutcome.transient) {
    return SharingException(SharingProblem.offline, failure.code);
  }
  return SharingException(switch (failure.code) {
    'not_space_member' => SharingProblem.notMember,
    'space_owner_only' => SharingProblem.ownerOnly,
    'personal_space' => SharingProblem.personalSpace,
    'invalid_email' => SharingProblem.invalidEmail,
    'already_member' => SharingProblem.alreadyMember,
    'member_limit_reached' => SharingProblem.memberLimitReached,
    'invite_limit_reached' => SharingProblem.inviteLimitReached,
    'invite_unavailable' => SharingProblem.inviteUnavailable,
    'invite_other_email' => SharingProblem.inviteOtherEmail,
    'member_not_found' => SharingProblem.memberNotFound,
    'last_owner' => SharingProblem.lastOwner,
    'space_name_mismatch' => SharingProblem.nameMismatch,
    _ => SharingProblem.refused,
  }, failure.code);
}

/// Set in `main.dart` when the build carries the cloud configuration; `null`
/// otherwise (and in tests unless overridden).
final sharingServiceProvider = Provider<SharingService?>((ref) => null);
