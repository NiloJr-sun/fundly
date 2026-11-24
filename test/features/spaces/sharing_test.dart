import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spaces/data/sharing_service.dart';
import 'package:fundly/features/spaces/data/space_directory.dart';
import 'package:fundly/features/spaces/domain/space.dart';
import 'package:fundly/features/spaces/domain/space_invite.dart';
import 'package:fundly/features/spaces/domain/space_member.dart';
import 'package:fundly/features/spaces/presentation/sharing_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../helpers/fake_synced_store.dart';

const me = '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d';

void main() {
  group('members', () {
    test('label: name, else email, else "Member"', () {
      const base = SpaceMember(userId: 'u', role: SpaceRole.editor);
      expect(
        const SpaceMember(
          userId: 'u',
          role: SpaceRole.editor,
          email: 'ana@test.com',
          displayName: ' Ana ',
        ).label,
        'Ana',
      );
      expect(
        const SpaceMember(
          userId: 'u',
          role: SpaceRole.editor,
          email: 'ana@test.com',
          displayName: '  ',
        ).label,
        'ana@test.com',
      );
      expect(base.label, 'Member');
    });

    test('owners, editors, then viewers, each by name', () {
      const members = [
        SpaceMember(userId: '1', role: SpaceRole.viewer, displayName: 'Ana'),
        SpaceMember(userId: '2', role: SpaceRole.owner, displayName: 'zed'),
        SpaceMember(userId: '3', role: SpaceRole.editor, displayName: 'Bo'),
        SpaceMember(userId: '4', role: SpaceRole.owner, displayName: 'Cy'),
      ];
      expect(sortedMembers(members).map((m) => m.userId), ['4', '2', '3', '1']);
    });

    test('read from the store with their emails and names', () async {
      final store = FakeSyncedStore(const SignedIn(userId: me, email: ''));
      addTearDown(store.close);
      const at = '2026-11-24 00:00:00+00';
      Map<String, Object?> member(
        String space,
        String user,
        String role, {
        String? email,
        String? name,
      }) => {
        'id': '$space:$user',
        'space_id': space,
        'user_id': user,
        'role': role,
        'email': email,
        'display_name': name,
        'created_at': at,
        'updated_at': at,
      };
      await store.download({
        'space_members': [
          member('s1', me, 'owner', email: 'me@test.com', name: 'Me'),
          member('s1', 'u2', 'viewer', email: 'ana@test.com'),
          member('s2', 'u3', 'owner', name: 'Elsewhere'),
        ],
      });
      final members = await watchMembers(store.database, 's1').first;
      expect(members, const [
        SpaceMember(
          userId: me,
          role: SpaceRole.owner,
          email: 'me@test.com',
          displayName: 'Me',
        ),
        SpaceMember(
          userId: 'u2',
          role: SpaceRole.viewer,
          email: 'ana@test.com',
        ),
      ]);
      // Removal (the stream deleting the row) updates the list.
      await store.database.customUpdate(
        "DELETE FROM space_members WHERE user_id = 'u2'",
        updates: {store.database.syncedSpaceMembers},
        updateKind: UpdateKind.delete,
      );
      expect(
        (await watchMembers(store.database, 's1').first).map((m) => m.userId),
        [me],
      );
    });
  });

  group('invite email', () {
    test('trimmed and lower-cased like the server', () {
      expect(normalizeInviteEmail('  Ana@Test.COM '), 'ana@test.com');
      expect(inviteEmailProblem('  Ana@Test.COM ', const []), isNull);
    });

    test('empty, malformed or too long', () {
      expect(inviteEmailProblem('  ', const []), 'Enter an email');
      for (final bad in ['ana', '@test.com', 'ana@', 'a na@test.com']) {
        expect(inviteEmailProblem(bad, const []), 'Enter a valid email');
      }
      expect(
        inviteEmailProblem('${'a' * 250}@t.co', const []),
        'Enter a valid email',
      );
    });

    test('an existing member cannot be invited again', () {
      expect(
        inviteEmailProblem('ANA@test.com', const ['ana@test.com', null]),
        'Already a member of this space',
      );
    });

    test('invites give editor or viewer only', () {
      expect(inviteRoles, [SpaceRole.editor, SpaceRole.viewer]);
    });

    test('preview names the inviter by name, else email', () {
      InvitePreview preview({String? name, String? email}) => InvitePreview(
        spaceId: 's',
        spaceName: 'Household',
        role: SpaceRole.editor,
        expiresAt: DateTime.utc(2026, 12),
        alreadyMember: false,
        inviterName: name,
        inviterEmail: email,
      );
      expect(preview(name: 'Ana', email: 'a@t.co').inviterLabel, 'Ana');
      expect(preview(name: '', email: 'a@t.co').inviterLabel, 'a@t.co');
      expect(preview().inviterLabel, isNull);
    });
  });

  group('sharing errors', () {
    SharingProblem problem(String message, {String code = 'P0001'}) =>
        sharingExceptionFor(PostgrestException(message: message, code: code))
            .problem;

    test('every server code has its problem', () {
      const expected = {
        'not_space_member': SharingProblem.notMember,
        'space_owner_only': SharingProblem.ownerOnly,
        'personal_space': SharingProblem.personalSpace,
        'invalid_email': SharingProblem.invalidEmail,
        'already_member': SharingProblem.alreadyMember,
        'member_limit_reached': SharingProblem.memberLimitReached,
        'invite_limit_reached': SharingProblem.inviteLimitReached,
        'invite_unavailable': SharingProblem.inviteUnavailable,
        'invite_other_email': SharingProblem.inviteOtherEmail,
        'member_not_found': SharingProblem.memberNotFound,
        'last_owner': SharingProblem.lastOwner,
        'space_name_mismatch': SharingProblem.nameMismatch,
        'something_new': SharingProblem.refused,
      };
      for (final MapEntry(:key, :value) in expected.entries) {
        expect(problem(key), value, reason: key);
      }
      expect(problem('invalid_request', code: '22023'), SharingProblem.refused);
    });

    test('no answer or a busy server is offline', () {
      expect(
        sharingExceptionFor(Exception('socket')).problem,
        SharingProblem.offline,
      );
      expect(problem('', code: '503'), SharingProblem.offline);
      expect(
        problem('authentication_required', code: '28000'),
        SharingProblem.offline,
      );
    });

    test('every problem has its own plain words', () {
      final messages = {
        for (final problem in SharingProblem.values)
          sharingProblemMessage(problem),
      };
      expect(messages, hasLength(SharingProblem.values.length));
      expect(messages.every((m) => !m.contains('_')), isTrue);
    });
  });
}
