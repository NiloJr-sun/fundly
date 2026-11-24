import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/batch_uploader.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spaces/data/space_directory.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../helpers/fake_synced_store.dart';

const me = '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d';
const other = '00000000-0000-4000-8000-000000000001';

void main() {
  test('lists my spaces, Personal first then by name, with my role', () async {
    final store = FakeSyncedStore(const SignedIn(userId: me, email: ''));
    addTearDown(store.close);
    final db = store.database;
    const at = '2026-11-24 00:00:00+00';
    Future<void> space(String id, String name, {String? personalOf}) =>
        db.customStatement(
          'INSERT INTO spaces (id, name, personal_of, created_by, created_at, '
          'updated_at, revision) VALUES (?, ?, ?, ?, ?, ?, 2)',
          [id, name, personalOf, personalOf ?? me, at, at],
        );
    Future<void> member(String space, String user, String role) =>
        db.customStatement(
          'INSERT INTO space_members (id, space_id, user_id, role, created_at, '
          'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
          ['$space:$user', space, user, role, at, at],
        );
    await space(me, 'Personal', personalOf: me);
    await space('s-b', 'business');
    await space('s-a', 'Allowance');
    await space('s-x', 'Not mine');
    await member(me, me, 'owner');
    await member('s-b', me, 'owner');
    await member('s-a', me, 'editor');
    await member('s-x', other, 'owner');

    final spaces = await watchSpaces(db, me).first;
    expect(spaces.map((s) => s.name), ['Personal', 'Allowance', 'business']);
    expect(spaces.first.isPersonal, isTrue);
    expect(spaces[1].role, SpaceRole.editor);
    expect(spaces[1].canRename, isFalse);
    expect(spaces[2].canRename, isTrue);
    expect(spaces[2].revision, 2);
    // Leaving a space (as the stream would delete its membership) updates
    // the list.
    await db.customUpdate(
      "DELETE FROM space_members WHERE space_id = 's-a'",
      updates: {db.syncedSpaceMembers},
      updateKind: UpdateKind.delete,
    );
    expect((await watchSpaces(db, me).first).map((s) => s.id), [me, 's-b']);
  });

  group('space errors', () {
    SpaceProblem problem(String message) =>
        spaceExceptionFor(PostgrestException(message: message, code: 'P0001'))
            .problem;

    test('map to what the screen says', () {
      expect(problem('invalid_name'), SpaceProblem.invalidName);
      expect(problem('name_taken'), SpaceProblem.nameTaken);
      expect(problem('space_limit_reached'), SpaceProblem.limitReached);
      expect(problem('revision_conflict'), SpaceProblem.changed);
      expect(problem('space_owner_only'), SpaceProblem.refused);
      expect(problem('not_space_member'), SpaceProblem.refused);
    });

    test('no connection is offline', () {
      expect(
        spaceExceptionFor(Exception('socket')).problem,
        SpaceProblem.offline,
      );
      expect(
        spaceExceptionFor(
          const SyncUploadException(UploadOutcome.transient, 'x'),
        ).problem,
        SpaceProblem.offline,
      );
    });
  });
}
