import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sqlite_async/sqlite_async.dart';

import 'synced_database.dart';

/// Why a refused change is in the log (supabase/SYNC_PROTOCOL.md).
enum RejectionKind {
  /// The server refused it.
  rejected('rejected'),

  /// Never sent: it relied on a record that a refused change would have
  /// created.
  dependencyRejected('dependency_rejected');

  const RejectionKind(this.wireName);

  /// The value stored in `sync_rejections.kind`.
  final String wireName;

  static RejectionKind fromWire(String value) =>
      values.singleWhere((kind) => kind.wireName == value);
}

/// One refused change: a queued batch the server will never apply.
class SyncRejection {
  const SyncRejection({
    required this.batchId,
    required this.kind,
    required this.items,
    required this.labels,
    required this.rejectedAt,
    this.code,
    this.detail,
    this.causedBy,
  });

  factory SyncRejection.fromRow(SyncRejectionRow row) => SyncRejection(
    batchId: row.batchId,
    kind: RejectionKind.fromWire(row.kind),
    code: row.code,
    detail: row.detail,
    causedBy: row.causedBy,
    items: [
      for (final item
          in (jsonDecode(row.operations) as Map<String, Object?>)['items']!
              as List<Object?>)
        item! as Map<String, Object?>,
    ],
    labels: (jsonDecode(row.labels) as Map<String, Object?>).cast(),
    rejectedAt: DateTime.parse(row.rejectedAt).toUtc(),
  );

  final String batchId;
  final RejectionKind kind;

  /// The server's message code, such as `revision_conflict`; null when the
  /// change was never sent.
  final String? code;
  final String? detail;

  /// For [RejectionKind.dependencyRejected]: the batch it relied on.
  final String? causedBy;

  /// The batch's items as queued (`operation`, `id`, `data`, ...).
  final List<Map<String, Object?>> items;

  /// Record ID → name or payee as shown when the change was refused.
  final Map<String, String> labels;
  final DateTime rejectedAt;
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

List<Map<String, Object?>> _items(Map<String, Object?> envelope) => [
  for (final item in envelope['items']! as List<Object?>)
    item! as Map<String, Object?>,
];

/// The IDs a batch would create: every `*.create` target, an account's
/// liability row, and a plan saved without a `previous` one.
Set<String> createdIdsOf(Map<String, Object?> envelope) => {
  for (final item in _items(envelope)) ...[
    if ((item['operation']! as String).endsWith('.create'))
      item['id']! as String,
    if (item['operation'] == 'account.create')
      if ((item['data'] as Map?)?['linked_category_id'] case final String id)
        id,
    if (item['operation'] == 'plan.save' &&
        (item['data'] as Map?)?['previous'] == null)
      item['id']! as String,
  ],
};

/// Every record ID a batch mentions: targets and references in its data.
Set<String> referencedIdsOf(Map<String, Object?> envelope) {
  final ids = <String>{};
  void visit(Object? value) {
    switch (value) {
      case final String text when _uuid.hasMatch(text):
        ids.add(text);
      case final Map<Object?, Object?> map:
        map.values.forEach(visit);
      case final List<Object?> list:
        list.forEach(visit);
    }
  }

  for (final item in _items(envelope)) {
    visit(item['id']);
    visit(item['data']);
  }
  return ids;
}

/// The logged refused batch whose would-be records [envelope] refers to, or
/// null. A batch's own earlier entry (left by a crash before the queue moved
/// on) does not count.
Future<String?> dependencyOf(
  SqliteReadContext database,
  String batchId,
  Map<String, Object?> envelope,
) async {
  final referenced = referencedIdsOf(envelope);
  if (referenced.isEmpty) return null;
  final rows = await database.getAll(
    'SELECT batch_id, created_ids FROM sync_rejections '
    'WHERE batch_id <> ? ORDER BY rejected_at, batch_id',
    [batchId],
  );
  for (final row in rows) {
    final created = (jsonDecode(row['created_ids'] as String) as List<Object?>)
        .cast<String>();
    if (created.any(referenced.contains)) return row['batch_id'] as String;
  }
  return null;
}

/// The five synchronized tables, as PowerSync names them.
const _syncedTables = [
  'custom_account_types',
  'accounts',
  'categories',
  'transactions',
  'monthly_plans',
];

/// Logs a refused batch and marks every synchronized row for PowerSync to
/// restore, in one local transaction.
///
/// Marked rows (`ps_updated_rows`) are put back to the server's version by
/// the next applied download checkpoint, which PowerSync runs only once the
/// upload queue is empty: a refused insert disappears, a refused edit is
/// undone and a refused delete comes back. Marking every row, including the
/// ones only the download log still holds, covers side effects without
/// knowing what each write touched. Logging the same batch again keeps the
/// first entry.
Future<void> recordRejection(
  SqliteConnection database, {
  required String batchId,
  required Map<String, Object?> envelope,
  required RejectionKind kind,
  required DateTime now,
  String? code,
  String? detail,
  String? causedBy,
}) => database.writeTransaction((transaction) async {
  final labels = await _labels(transaction, referencedIdsOf(envelope).toList());
  await transaction.execute(
    'INSERT OR IGNORE INTO sync_rejections (batch_id, kind, code, detail, '
    'caused_by, operations, created_ids, labels, rejected_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      batchId,
      kind.wireName,
      code,
      detail,
      causedBy,
      jsonEncode(envelope),
      jsonEncode(createdIdsOf(envelope).toList()),
      jsonEncode(labels),
      now.toUtc().toIso8601String(),
    ],
  );
  for (final table in _syncedTables) {
    await transaction.execute(
      'INSERT OR IGNORE INTO ps_updated_rows (row_type, row_id) '
      "SELECT '$table', id FROM $table",
    );
  }
  await transaction.execute(
    'INSERT OR IGNORE INTO ps_updated_rows (row_type, row_id) '
    'SELECT row_type, row_id FROM ps_oplog',
  );
});

/// Removes a batch's entry: it was accepted on a later attempt (a crash had
/// left it logged before the queue moved on).
Future<void> forgetRejection(SqliteConnection database, String batchId) =>
    database.execute('DELETE FROM sync_rejections WHERE batch_id = ?', [
      batchId,
    ]);

Future<Map<String, String>> _labels(
  SqliteReadContext database,
  List<String> ids,
) async {
  if (ids.isEmpty) return const {};
  final rows = await database.getAll(
    'WITH wanted(id) AS (SELECT value FROM json_each(?1)) '
    'SELECT id, name AS label FROM custom_account_types '
    'WHERE id IN wanted '
    'UNION ALL SELECT id, name FROM accounts WHERE id IN wanted '
    'UNION ALL SELECT id, name FROM categories WHERE id IN wanted '
    'UNION ALL SELECT id, payee FROM transactions WHERE id IN wanted '
    'UNION ALL SELECT p.id, c.name FROM monthly_plans p '
    'JOIN categories c ON c.id = p.category_id WHERE p.id IN wanted',
    [jsonEncode(ids)],
  );
  return {
    for (final row in rows)
      if ((row['label'] as String).isNotEmpty)
        row['id'] as String: row['label'] as String,
  };
}

/// The refused-changes log, for the screen that lists it.
extension SyncRejectionLog on SyncedDatabase {
  /// Newest first.
  Stream<List<SyncRejection>> watchRejections() =>
      (select(syncRejections)..orderBy([
            (r) => OrderingTerm.desc(r.rejectedAt),
            (r) => OrderingTerm.desc(r.batchId),
          ]))
          .watch()
          .map((rows) => [for (final row in rows) SyncRejection.fromRow(row)]);

  Future<void> dismissRejection(String batchId) =>
      (delete(syncRejections)..where((r) => r.batchId.equals(batchId))).go();

  Future<void> dismissAllRejections() => delete(syncRejections).go();
}
