import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/auth_identity.dart';
import '../database/database_name.dart';
import 'preview_cleanup.dart';
import 'synced_database.dart';
import 'synced_store.dart';

/// The five tables PowerSync fills (public for tests). Their columns are inferred from the
/// tables Drift creates, so the two cannot drift apart.
final syncedRawSchema = ps.Schema(
  const [],
  rawTables: [
    for (final table in [
      'custom_account_types',
      'accounts',
      'categories',
      'transactions',
      'monthly_plans',
    ])
      ps.RawTable.inferred(name: table, schema: const ps.RawTableSchema()),
  ],
);

/// The synchronized store on PowerSync (cloud sync S5.2): downloads only.
///
/// Opening is asynchronous, but the [database] is usable at once: its
/// queries wait until PowerSync and Drift are ready. Nothing is written
/// locally until uploads arrive (S5.3), so there are no capture triggers.
class PowerSyncStore implements SyncedStore {
  PowerSyncStore._(this._identity, this._client, this._powerSyncUrl) {
    database = SyncedDatabase(DatabaseConnection.delayed(_openConnection()));
    unawaited(_start());
  }

  /// Opens the store for [identity] and starts downloading. [powerSyncUrl]
  /// may be empty (a build without it): the store then never connects.
  factory PowerSyncStore.open(
    SignedIn identity, {
    required SupabaseClient client,
    required String powerSyncUrl,
  }) => PowerSyncStore._(identity, client, powerSyncUrl);

  final SignedIn _identity;
  final SupabaseClient _client;
  final String _powerSyncUrl;
  final _sync = Completer<ps.PowerSyncDatabase>();
  final _state = StreamController<SyncState>.broadcast();
  late SyncState _current = SyncState(
    connection: _powerSyncUrl.isEmpty
        ? SyncConnection.notConfigured
        : SyncConnection.connecting,
  );
  StreamSubscription<ps.SyncStatus>? _statusSubscription;
  bool _closed = false;

  @override
  late final SyncedDatabase database;

  Future<DatabaseConnection> _openConnection() async {
    final name = databaseNameFor(_identity);
    final sync = ps.PowerSyncDatabase(
      schema: const ps.Schema([]),
      path: kIsWeb
          ? '$name.db'
          : '${(await getApplicationDocumentsDirectory()).path}/$name.db',
      sqliteOptions: const SqliteOptions(
        webSqliteOptions: WebSqliteOptions(
          wasmUri: 'powersync/sqlite3.wasm',
          workerUri: 'powersync/powersync_db.worker.js',
        ),
      ),
    );
    await sync.initialize();
    _sync.complete(sync);
    return SqliteAsyncDriftConnection(sync);
  }

  Future<void> _start() async {
    try {
      // Opening runs Drift's migrations, which create the raw tables; the
      // download mapping is inferred from them afterwards.
      await database.customSelect('SELECT 1').get();
      final sync = await _sync.future;
      await sync.updateSchema(syncedRawSchema);
      await deletePreviewDatabase(previewDatabaseNameFor(_identity.userId));
      if (_closed || _powerSyncUrl.isEmpty) return;
      _statusSubscription = sync.statusStream.listen(_onStatus);
      await sync.connect(
        connector: _DownloadConnector(_client, _powerSyncUrl, _identity),
      );
    } on Object catch (error) {
      _emit(SyncState(connection: SyncConnection.failed, error: '$error'));
    }
  }

  void _onStatus(ps.SyncStatus status) {
    final error = status.downloadError ?? status.uploadError;
    _emit(
      SyncState(
        connection: switch (status) {
          _ when error != null => SyncConnection.failed,
          ps.SyncStatus(connected: true) => SyncConnection.connected,
          ps.SyncStatus(connecting: true) => SyncConnection.connecting,
          _ => SyncConnection.offline,
        },
        hasSynced: status.hasSynced ?? false,
        lastSyncedAt: status.lastSyncedAt,
        error: error?.toString(),
      ),
    );
  }

  void _emit(SyncState state) {
    if (_closed || state == _current) return;
    _current = state;
    _state.add(state);
  }

  @override
  Stream<SyncState> watchState() async* {
    yield _current;
    yield* _state.stream;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _statusSubscription?.cancel();
    await _state.close();
    await database.close();
    if (_sync.isCompleted) {
      final sync = await _sync.future;
      await sync.disconnect();
      await sync.close();
    }
  }
}

/// Gives PowerSync the signed-in user's Supabase token. Nothing is uploaded
/// yet (S5.3), so [uploadData] has nothing to send.
class _DownloadConnector extends ps.PowerSyncBackendConnector {
  _DownloadConnector(this._client, this._endpoint, this._identity);

  final SupabaseClient _client;
  final String _endpoint;
  final SignedIn _identity;

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async {
    var session = _client.auth.currentSession;
    // Never download one user's data with another user's token.
    if (session == null || session.user.id != _identity.userId) return null;
    if (session.isExpired) {
      session = (await _client.auth.refreshSession()).session;
      if (session == null || session.user.id != _identity.userId) return null;
    }
    return ps.PowerSyncCredentials(
      endpoint: _endpoint,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {}
}
