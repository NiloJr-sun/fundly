import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../domain/space.dart';
import '../domain/space_member.dart';

/// The spaces [userId] belongs to, as downloaded into [database] (every
/// store holds the same list).
Stream<List<Space>> watchSpaces(SyncedDatabase database, String userId) =>
    database
        .customSelect(
          'SELECT s.id, s.name, s.personal_of, s.revision, m.role '
          'FROM spaces s JOIN space_members m '
          'ON m.space_id = s.id AND m.user_id = ?',
          variables: [Variable.withString(userId)],
          readsFrom: {database.syncedSpaces, database.syncedSpaceMembers},
        )
        .watch()
        .map(
          (rows) => sortedSpaces([
            for (final row in rows)
              Space(
                id: row.read<String>('id'),
                name: row.read<String>('name'),
                isPersonal: row.read<String?>('personal_of') != null,
                role: SpaceRole.fromWire(row.read<String>('role')),
                revision: row.read<int>('revision'),
              ),
          ]),
        );

/// The signed-in user's spaces, from the active store; empty while signed out
/// or before the list has downloaded.
final spacesProvider = StreamProvider<List<Space>>((ref) {
  final identity = ref.watch(authIdentityProvider);
  final store = ref.watch(syncedStoreProvider);
  if (identity is! SignedIn || store == null) return Stream.value(const []);
  return watchSpaces(store.database, identity.userId);
});

/// The members of [spaceId], as downloaded into [database]; empty for a
/// space the user does not belong to.
Stream<List<SpaceMember>> watchMembers(
  SyncedDatabase database,
  String spaceId,
) =>
    (database.select(
      database.syncedSpaceMembers,
    )..where((member) => member.spaceId.equals(spaceId))).watch().map(
      (rows) => sortedMembers([
        for (final row in rows)
          SpaceMember(
            userId: row.userId,
            role: SpaceRole.fromWire(row.role),
            email: row.email,
            displayName: row.displayName,
          ),
      ]),
    );

/// The members of a space the user belongs to, from the active store (every
/// store holds every space's members); empty while signed out.
final spaceMembersProvider = StreamProvider.family<List<SpaceMember>, String>((
  ref,
  spaceId,
) {
  final store = ref.watch(syncedStoreProvider);
  if (store == null) return Stream.value(const []);
  return watchMembers(store.database, spaceId);
});
