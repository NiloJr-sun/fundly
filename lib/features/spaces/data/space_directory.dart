import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../domain/space.dart';

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
