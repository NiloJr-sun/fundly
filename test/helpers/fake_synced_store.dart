import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fundly/core/sync/synced_database.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';

/// A synchronized store in memory, without PowerSync. Tests insert rows with
/// [download] as if PowerSync had downloaded them.
class FakeSyncedStore implements SyncedStore {
  FakeSyncedStore(
    this.identity, {
    SyncState state = const SyncState(
      connection: SyncConnection.connected,
      hasSynced: true,
    ),
  }) : _current = state;

  final SignedIn identity;

  /// Created on first use, so widget tests that never read records open no
  /// database (and leave no drift timers behind).
  @override
  late final SyncedDatabase database = _open();
  bool _opened = false;

  SyncedDatabase _open() {
    _opened = true;
    return SyncedDatabase(
      NativeDatabase.memory(
        // Stands in for PowerSync's upload queue, which repositories write to.
        setup: (database) => database.execute(
          'CREATE TABLE powersync_crud '
          '(seq INTEGER PRIMARY KEY, op TEXT, id TEXT, type TEXT, data TEXT)',
        ),
      ),
    );
  }

  final _states = StreamController<SyncState>.broadcast();
  SyncState _current;
  bool closed = false;

  set state(SyncState value) {
    _current = value;
    _states.add(value);
  }

  @override
  Stream<SyncState> watchState() async* {
    yield _current;
    yield* _states.stream;
  }

  /// What [watchPendingUploads] reports (the fake does not count its queue).
  int pendingUploads = 0;

  @override
  Stream<int> watchPendingUploads() => Stream.value(pendingUploads);

  /// The queued batches, oldest first, as uploaded to the server.
  Future<List<QueuedBatch>> queuedBatches() async => [
    for (final row
        in await database
            .customSelect(
              'SELECT op, id, type, data FROM powersync_crud ORDER BY seq',
            )
            .get())
      (
        id: row.read<String>('id'),
        type: row.read<String>('type'),
        envelope: jsonDecode(row.read<String>('data')) as Map<String, Object?>,
      ),
  ];

  /// The items of every queued batch, in order.
  Future<List<Map<String, Object?>>> queuedItems() async => [
    for (final batch in await queuedBatches())
      for (final item in batch.envelope['items']! as List<Object?>)
        item! as Map<String, Object?>,
  ];

  @override
  Future<void> close() async {
    closed = true;
    await _states.close();
    if (_opened) await database.close();
  }

  /// Inserts rows the way a download checkpoint does: in one transaction, in
  /// any order (foreign keys are deferred).
  Future<void> download(Map<String, List<Map<String, Object?>>> rows) =>
      database.transaction(() async {
        for (final MapEntry(key: table, value: list) in rows.entries) {
          for (final row in list) {
            final columns = row.keys.join(', ');
            final marks = List.filled(row.length, '?').join(', ');
            await database.customInsert(
              'INSERT OR REPLACE INTO $table ($columns) VALUES ($marks)',
              variables: [for (final value in row.values) _variable(value)],
              // Like PowerSync's update notifications, so watchers refresh.
              updates: {
                database.allTables.singleWhere(
                  (t) => t.actualTableName == table,
                ),
              },
            );
          }
        }
      });
}

Variable<Object> _variable(Object? value) => switch (value) {
  null => const Variable(null),
  final int number => Variable.withInt(number),
  final String text => Variable.withString(text),
  _ => throw ArgumentError.value(value),
};

typedef QueuedBatch = ({String id, String type, Map<String, Object?> envelope});

/// Delete rows the way a download does.
extension FakeSyncedStoreDeletes on FakeSyncedStore {
  Future<void> deleteDownloaded(String table, String id) =>
      database.customUpdate(
        'DELETE FROM $table WHERE id = ?',
        variables: [Variable.withString(id)],
        updates: {
          database.allTables.singleWhere((t) => t.actualTableName == table),
        },
        updateKind: UpdateKind.delete,
      );
}

/// Row builders with the server's defaults, so tests state only what matters.
abstract final class SyncedRows {
  static const _at = '2026-11-16 09:30:00.000Z';

  static Map<String, Object?> account(
    String id,
    String name, {
    String type = 'savingsCash',
    int openingMinor = 0,
    bool archived = false,
    bool budget = false,
    String? customTypeId,
    String createdAt = _at,
  }) => {
    'id': id,
    'name': name,
    'type': type,
    'opening_balance_minor': openingMinor,
    'currency_code': 'PHP',
    'is_archived': archived ? 1 : 0,
    'custom_type_id': customTypeId,
    'is_budget_account': budget ? 1 : 0,
    'created_at': createdAt,
    'updated_at': createdAt,
    'revision': 1,
  };

  static Map<String, Object?> category(
    String id,
    String name, {
    String kind = 'spending',
    String planGroup = 'spending',
    String? linkedAccountId,
    bool archived = false,
    bool planArchived = false,
    String createdAt = _at,
  }) => {
    'id': id,
    'name': name,
    'kind': kind,
    'is_archived': archived ? 1 : 0,
    'is_plan_archived': planArchived ? 1 : 0,
    'is_plan_deleted': 0,
    'plan_group': planGroup,
    'linked_account_id': linkedAccountId,
    'created_at': createdAt,
    'updated_at': createdAt,
    'revision': 1,
  };

  static Map<String, Object?> transaction(
    String id, {
    String type = 'spending',
    int amountMinor = 10000,
    String date = '2026-11-16',
    String payee = 'Store',
    String? categoryId,
    String? sourceAccountId,
    String? destinationAccountId,
    String createdAt = _at,
    int revision = 1,
  }) => {
    'id': id,
    'type': type,
    'amount_minor': amountMinor,
    'currency_code': 'PHP',
    'date': date,
    'payee': payee,
    'category_id': categoryId,
    'source_account_id': sourceAccountId,
    'destination_account_id': destinationAccountId,
    'note': '',
    'created_at': createdAt,
    'updated_at': createdAt,
    'revision': revision,
  };

  static Map<String, Object?> plan(
    String id, {
    required String categoryId,
    String month = '2026-11',
    int? targetMinor,
    int assignedMinor = 0,
    String createdAt = _at,
  }) => {
    'id': id,
    'month': month,
    'category_id': categoryId,
    'target_amount_minor': targetMinor,
    'assigned_amount_minor': assignedMinor,
    'currency_code': 'PHP',
    'created_at': createdAt,
    'updated_at': createdAt,
    'revision': 1,
  };

  static Map<String, Object?> customType(
    String id,
    String name, {
    String baseType = 'savingsCash',
  }) => {
    'id': id,
    'name': name,
    'base_type': baseType,
    'created_at': _at,
    'updated_at': _at,
    'revision': 1,
  };
}
