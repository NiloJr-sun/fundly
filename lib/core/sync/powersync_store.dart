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
import 'batch_uploader.dart';
import 'dataset_initializer.dart';
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

/// Maps PowerSync's status to the status line's [SyncState] (public for
/// tests).
///
/// [lastUploadFailure] is the connector's own record of the failing upload.
/// On web, PowerSync runs sync in a shared worker and hands [uploadError]
/// back as plain text, so whether the server refused a change (stuck) is
/// only known from that record. A temporary upload failure (offline, server
/// busy) is retried with the same batch and not shown as an error: the
/// pending count already says changes are waiting.
SyncState syncStateFor({
  required bool connected,
  required bool connecting,
  required bool hasSynced,
  required DateTime? lastSyncedAt,
  required Object? downloadError,
  required Object? uploadError,
  SyncUploadException? lastUploadFailure,
}) {
  final upload = uploadError is SyncUploadException
      ? uploadError
      : uploadError == null
      ? null
      : lastUploadFailure;
  final stuck = upload != null && upload.isStuck ? upload : null;
  final error = downloadError ?? stuck;
  return SyncState(
    connection: switch (error) {
      _ when stuck != null && downloadError == null => SyncConnection.stuck,
      _? => SyncConnection.failed,
      _ when connected => SyncConnection.connected,
      _ when connecting => SyncConnection.connecting,
      _ => SyncConnection.offline,
    },
    hasSynced: hasSynced,
    lastSyncedAt: lastSyncedAt,
    error: error?.toString(),
  );
}

/// The synchronized store on PowerSync (cloud sync S5.2, uploads in S5.3).
///
/// Opening is asynchronous, but the [database] is usable at once: its
/// queries wait until PowerSync and Drift are ready. Repositories queue their
/// own upload batches (`SyncQueue`), so there are no capture triggers.
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
  _SupabaseConnector? _connector;
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
      // Absolute URLs: the worker fetches the wasm itself, and a relative
      // path there resolves against the worker's folder (powersync/), not
      // the page.
      sqliteOptions: SqliteOptions(
        webSqliteOptions: WebSqliteOptions(
          wasmUri: Uri.base.resolve('powersync/sqlite3.wasm').toString(),
          workerUri: Uri.base
              .resolve('powersync/powersync_db.worker.js')
              .toString(),
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
      unawaited(_deletePreviewDatabase());
      if (_closed || _powerSyncUrl.isEmpty) return;
      final firstDownload = !(sync.currentStatus.hasSynced ?? false);
      final connector = _connector = _SupabaseConnector(
        _client,
        _powerSyncUrl,
        _identity,
      );
      _statusSubscription = sync.statusStream.listen(_onStatus);
      await sync.connect(connector: connector);
      if (firstDownload) {
        await sync.waitForFirstSync();
        if (!_closed) await initializeDatasetIfEmpty(database);
      }
    } on Object catch (error) {
      _emit(SyncState(connection: SyncConnection.failed, error: '$error'));
    }
  }

  /// Deletes the S4 preview database in the background, so cleanup never
  /// holds up sync: a browser delete waits while another tab has the
  /// database open. A failure is retried on the next sign-in.
  Future<void> _deletePreviewDatabase() async {
    try {
      await deletePreviewDatabase(previewDatabaseNameFor(_identity.userId));
    } on Object catch (error) {
      debugPrint('Could not delete the preview database: $error');
    }
  }

  void _onStatus(ps.SyncStatus status) {
    _emit(
      syncStateFor(
        connected: status.connected,
        connecting: status.connecting,
        hasSynced: status.hasSynced ?? false,
        lastSyncedAt: status.lastSyncedAt,
        downloadError: status.downloadError,
        uploadError: status.uploadError,
        lastUploadFailure: _connector?.lastUploadFailure,
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
  Stream<int> watchPendingUploads() async* {
    final sync = await _sync.future;
    yield* sync
        .watch(
          'SELECT count(*) AS pending FROM ps_crud',
          triggerOnTables: const {'ps_crud'},
        )
        .map((rows) => rows.first['pending'] as int);
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

/// Gives PowerSync the signed-in user's Supabase token and uploads queued
/// batches to `fundly_apply_operations`.
class _SupabaseConnector extends ps.PowerSyncBackendConnector {
  _SupabaseConnector(this._client, this._endpoint, this._identity);

  final SupabaseClient _client;
  final String _endpoint;
  final SignedIn _identity;

  /// Why the last upload attempt failed, or null after one that did not
  /// throw this. Kept here because the web sync worker passes the error back
  /// only as text (see [syncStateFor]).
  SyncUploadException? lastUploadFailure;

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

  /// Uploads every queued batch, oldest first, stopping at the first that
  /// fails; PowerSync calls again later.
  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {
    lastUploadFailure = null;
    try {
      // Never upload one user's changes with another user's token.
      if (_client.auth.currentSession?.user.id != _identity.userId) {
        throw const SyncUploadException(UploadOutcome.transient, 'signed_out');
      }
      final apply = supabaseApplyBatch(_client);
      while (await uploadNextBatch(database, apply)) {}
    } on SyncUploadException catch (failure) {
      lastUploadFailure = failure;
      rethrow;
    }
  }
}
