import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../time/calendar_date.dart';
import 'synced_database.dart';

/// The `type` of every queued upload in PowerSync's queue: one protocol-1
/// batch for `fundly_apply_operations` (supabase/SYNC_PROTOCOL.md).
const syncBatchType = 'fundly_batch';

/// One item of a protocol-1 batch.
class SyncOperation {
  const SyncOperation(
    this.operation,
    this.id, {
    this.expectedRevision,
    this.data,
  });

  /// For example `transaction.create`.
  final String operation;

  /// The record the item addresses (for plan lifecycle, the category).
  final String id;

  /// The revision the server holds when this item is applied; `null` for
  /// creates and for operations without one.
  final int? expectedRevision;
  final Map<String, Object?>? data;

  Map<String, Object?> toJson() => {
    'operation': operation,
    'id': id,
    'expected_revision': ?expectedRevision?.toString(),
    'data': ?data,
  };
}

/// A new record or batch ID (UUID v4).
String newRecordId() => const Uuid().v4();

/// A timestamp as stored in the synchronized tables until the server's own
/// value is downloaded.
String syncedTimestamp(DateTime time) => time.toUtc().toIso8601String();

/// Money and revisions go over the wire as decimal strings, so web clients
/// never round them (WRITE_API.md).
String wireMinor(int minorUnits) => minorUnits.toString();

/// A date on the wire: strict `YYYY-MM-DD`, including year 0000.
String wireDate(CalendarDate date) => date.toIsoString();

/// Optimistic writes plus their upload.
extension SyncQueue on SyncedDatabase {
  /// Runs [body] in one local transaction together with queueing the
  /// operations it returns as one batch. The batch ID and payload are fixed
  /// here, so every retry sends the same request and the server applies it at
  /// most once. A body that returns no operations queues nothing.
  ///
  /// PowerSync does not apply downloads while the queue holds anything, so the
  /// optimistic rows stay until the server's state replaces them.
  Future<T> writeAndQueue<T>(
    Future<(T, List<SyncOperation>)> Function() body,
  ) => transaction(() async {
    final (result, operations) = await body();
    if (operations.isNotEmpty) {
      await customStatement(
        'INSERT INTO powersync_crud (op, id, type, data) VALUES (?, ?, ?, ?)',
        [
          'PUT',
          newRecordId(),
          syncBatchType,
          jsonEncode({
            'version': 1,
            'items': [for (final operation in operations) operation.toJson()],
          }),
        ],
      );
    }
    return result;
  });

  /// Queues a batch with no local change (dataset initialization).
  Future<void> queue(List<SyncOperation> operations) =>
      writeAndQueue(() async => (null, operations));
}

/// The next revision of an optimistically updated row. Every server update
/// adds exactly one (`fundly_set_revision`), so a later queued edit of the same
/// record carries the revision the server will hold by then.
int nextRevision(int revision) => revision + 1;

/// A case-insensitive name comparison for the synchronized tables, which have
/// no `NOCASE` collation. Matches the server's ASCII case-insensitive rule.
Expression<bool> sameNameAs(GeneratedColumn<String> column, String name) =>
    column.lower().equalsExp(Variable<String>(name).lower());
