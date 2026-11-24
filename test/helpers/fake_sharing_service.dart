import 'package:fundly/features/spaces/data/sharing_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';
import 'package:fundly/features/spaces/domain/space_invite.dart';

/// Records every sharing call; the next queued [failures] entry is thrown by
/// the next call instead.
class FakeSharingService implements SharingService {
  final calls = <String>[];
  final failures = <SharingException>[];
  List<SpaceInvite> invites = [];
  var _created = 0;

  void _record(String call) {
    calls.add(call);
    if (failures.isNotEmpty) throw failures.removeAt(0);
  }

  @override
  Future<CreatedInvite> createInvite({
    required String spaceId,
    required String email,
    required SpaceRole role,
  }) async {
    _record('invite $spaceId $email ${role.wireName}');
    _created++;
    return CreatedInvite(
      id: 'invite-$_created',
      secret: '${'ab' * 31}${_created.toString().padLeft(2, '0')}',
      email: email,
      role: role,
      expiresAt: DateTime.utc(2026, 12, 1),
    );
  }

  @override
  Future<List<SpaceInvite>> listInvites(String spaceId) async {
    _record('list $spaceId');
    return invites;
  }

  @override
  Future<void> revokeInvite(String inviteId) async =>
      _record('revoke $inviteId');

  /// What [previewInvite] returns; set by tests that open invites.
  InvitePreview? preview;

  @override
  Future<InvitePreview> previewInvite(String secret) async {
    _record('preview $secret');
    return preview!;
  }

  @override
  Future<JoinedSpace> acceptInvite(String secret) async {
    _record('accept $secret');
    return JoinedSpace(
      spaceId: preview!.spaceId,
      spaceName: preview!.spaceName,
      role: preview!.role,
    );
  }

  @override
  Future<void> declineInvite(String secret) async => _record('decline $secret');

  @override
  Future<void> setMemberRole({
    required String spaceId,
    required String userId,
    required SpaceRole role,
  }) async => _record('role $spaceId $userId ${role.wireName}');

  @override
  Future<void> removeMember({
    required String spaceId,
    required String userId,
  }) async => _record('remove $spaceId $userId');

  @override
  Future<void> leaveSpace(String spaceId) async => _record('leave $spaceId');

  @override
  Future<void> deleteSpace({
    required String spaceId,
    required String name,
  }) async => _record('delete $spaceId $name');
}
