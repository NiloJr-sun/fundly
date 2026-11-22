import 'dart:io';

import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/powersync_store.dart';
import 'package:fundly/core/sync/synced_database.dart';
import 'package:fundly/features/accounts/data/synced_account_repository.dart';
import 'package:powersync/powersync.dart' as ps;

/// The real PowerSync SDK on this machine's SQLite: Drift creates the raw
/// tables, PowerSync infers its download mapping from them, and rows written
/// through PowerSync's connection reach Drift's watchers.
void main() {
  late Directory directory;
  late ps.PowerSyncDatabase sync;
  late SyncedDatabase database;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('fundly_ps_');
    sync = ps.PowerSyncDatabase(
      schema: const ps.Schema([]),
      path: '${directory.path}/store.db',
    );
    await sync.initialize();
    database = SyncedDatabase(SqliteAsyncDriftConnection(sync));
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await database.close();
    await sync.close();
    directory.deleteSync(recursive: true);
  });

  test('the raw-table mapping is inferred from the Drift tables', () async {
    await sync.updateSchema(syncedRawSchema);
    // Reapplying on the next launch must work too.
    await sync.updateSchema(syncedRawSchema);
  });

  test('rows written on PowerSync connection reach Drift watchers', () async {
    await sync.updateSchema(syncedRawSchema);
    final repository = SyncedAccountRepository(database);
    final names = <List<String>>[];
    final subscription = repository.watchAll().listen(
      (list) => names.add([for (final a in list) a.name]),
    );
    await pumpEventQueue();
    await sync.writeTransaction(
      (tx) => tx.execute(
        'INSERT INTO accounts (id, name, type, opening_balance_minor, '
        'currency_code, is_archived, custom_type_id, is_budget_account, '
        'created_at, updated_at, revision) '
        "VALUES ('a', 'BDO', 'savingsCash', 0, 'PHP', 0, NULL, 0, "
        "'2026-11-16 09:30:00Z', '2026-11-16 09:30:00Z', 1)",
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await subscription.cancel();
    expect(names.last, ['BDO']);
  });
}
