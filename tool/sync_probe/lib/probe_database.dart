import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:uuid/uuid.dart';

part 'probe_database.g.dart';

class ProbeParents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get revision => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class ProbeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text()();
  IntColumn get amountMinor => integer()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    'FOREIGN KEY (parent_id) REFERENCES probe_parents(id) DEFERRABLE INITIALLY DEFERRED',
  ];
}

const managedSchema = ps.Schema([
  ps.Table('probe_parents', [
    ps.Column.text('name'),
    ps.Column.integer('revision'),
  ], trackPreviousValues: ps.TrackPreviousValuesOptions()),
  ps.Table('probe_entries', [
    ps.Column.text('parent_id'),
    ps.Column.integer('amount_minor'),
  ]),
]);

const rawSchema = ps.Schema(
  [],
  rawTables: [
    ps.RawTable.inferred(
      name: 'probe_parents',
      schema: ps.RawTableSchema(
        syncedColumns: ['name', 'revision'],
        options: ps.TableOptions(
          ignoreEmptyUpdates: true,
          trackPreviousValues: ps.TrackPreviousValuesOptions(),
        ),
      ),
    ),
    ps.RawTable.inferred(name: 'probe_entries', schema: ps.RawTableSchema()),
  ],
);

@DriftDatabase(tables: [ProbeParents, ProbeEntries])
class ProbeDatabase extends _$ProbeDatabase {
  ProbeDatabase(
    ps.PowerSyncDatabase database, {
    required this.raw,
    this.version = 1,
  }) : super(SqliteAsyncDriftConnection(database));

  final bool raw;
  final int version;
  @override
  int get schemaVersion => version;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Managed views already exist; only raw mode uses Drift's DDL.
    onCreate: (m) async {
      if (raw) {
        await m.createAll();
        if (version >= 2) await _addLocalNote();
      }
    },
    onUpgrade: (m, from, to) async {
      if (raw && from < 2 && to >= 2) await _addLocalNote();
    },
  );

  Future<void> _addLocalNote() =>
      customStatement('ALTER TABLE probe_parents ADD COLUMN local_note TEXT');

  Future<void> createPair(String parent, String child, {bool reject = false}) =>
      transaction(() async {
        await into(probeParents).insert(
          ProbeParentsCompanion.insert(
            id: parent,
            name: reject ? 'REJECT_PROBE' : 'Disposable parent',
            revision: 1,
          ),
        );
        await into(probeEntries).insert(
          ProbeEntriesCompanion.insert(
            id: child,
            parentId: parent,
            amountMinor: 12345,
          ),
        );
      });
}

class ProbeStore {
  ProbeStore._(this.sync, this.drift, this.installationId);
  final ps.PowerSyncDatabase sync;
  final ProbeDatabase drift;
  final String installationId;

  static Future<ProbeStore> open(
    String path, {
    bool raw = false,
    int version = 1,
  }) async {
    final sync = ps.PowerSyncDatabase(
      schema: raw ? const ps.Schema([]) : managedSchema,
      path: path,
      sqliteOptions: const SqliteOptions(
        webSqliteOptions: WebSqliteOptions(
          wasmUri:
              '${String.fromEnvironment('PROBE_ASSET_PREFIX')}sqlite3.wasm',
          workerUri:
              '${String.fromEnvironment('PROBE_ASSET_PREFIX')}powersync_db.worker.js',
        ),
      ),
    );
    await sync.initialize();
    await sync.writeLock((tx) => tx.execute('PRAGMA foreign_keys = ON'));
    final drift = ProbeDatabase(sync, raw: raw, version: version);
    // Open Drift (and run raw DDL) before inferring raw-table operations.
    await drift.customSelect('SELECT 1').get();
    if (raw) {
      await sync.updateSchema(rawSchema);
      await sync.writeTransaction((tx) async {
        for (final table in rawSchema.rawTables) {
          for (final operation in ['INSERT', 'UPDATE', 'DELETE']) {
            final trigger = '${table.name}_${operation.toLowerCase()}';
            await tx.execute('DROP TRIGGER IF EXISTS "$trigger"');
            await tx.execute(
              'SELECT powersync_create_raw_table_crud_trigger(?, ?, ?)',
              [jsonEncode(table), trigger, operation],
            );
          }
        }
      });
    }
    await sync.execute(
      'CREATE TABLE IF NOT EXISTS probe_installation '
      '(slot INTEGER PRIMARY KEY CHECK(slot = 1), id TEXT NOT NULL)',
    );
    await sync.execute(
      'INSERT OR IGNORE INTO probe_installation(slot, id) VALUES(1, ?)',
      [const Uuid().v4()],
    );
    final installation = await sync.get(
      'SELECT id FROM probe_installation WHERE slot = 1',
    );
    return ProbeStore._(sync, drift, installation['id'] as String);
  }

  Future<void> close() async {
    await drift.close();
    await sync.close();
  }
}
