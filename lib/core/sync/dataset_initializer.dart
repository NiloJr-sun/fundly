import 'package:drift/drift.dart';

import 'sync_queue.dart';
import 'synced_database.dart';

/// Asks the server once for the default categories (cloud sync S5.3,
/// Decision 4). Called after this device's first complete download: if the
/// dataset has no categories, a `dataset.initialize` batch is queued. The
/// server inserts the defaults only while the owner has none, so two devices
/// asking at once still get one set, which then arrives by download.
///
/// A viewer (shared spaces C3) asks nothing: the server would refuse the
/// write, and the space's owner or an editor gets the defaults instead. Pass
/// [spaceId] and [userId] so the store's own membership row decides.
///
/// Returns whether a request was queued.
Future<bool> initializeDatasetIfEmpty(
  SyncedDatabase database, {
  String? spaceId,
  String? userId,
}) async {
  if (spaceId != null && userId != null) {
    final members = database.syncedSpaceMembers;
    final row =
        await (database.select(members)..where(
              (member) =>
                  member.spaceId.equals(spaceId) & member.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (row?.role == 'viewer') return false;
  }
  final categories = database.syncedCategories;
  final count = categories.id.count();
  final existing = await (database.selectOnly(
    categories,
  )..addColumns([count])).map((row) => row.read(count)!).getSingle();
  if (existing > 0) return false;
  await database.queue([SyncOperation('dataset.initialize', newRecordId())]);
  return true;
}
