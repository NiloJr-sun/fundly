import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/auth_identity.dart';
import '../database/database_name.dart';
import 'batch_uploader.dart';
import 'dataset_initializer.dart';
import 'preview_cleanup.dart';
import 'store_files.dart';
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
      'spaces',
      'space_members',
    ])
      ps.RawTable.inferred(name: table, schema: const ps.RawTableSchema()),
  ],
);

/// Maps PowerSync's status to the status line's [SyncState] (public for
/// tests).
///
/// [lastUploadFailure] is the connector's own record of the failing upload.
/// On web, PowerSync runs sync in a shared worker and hands [uploadError]
/// back as plain text, so whether the upload is blocked (stuck) is only
/// known from that record. A temporary upload failure (offline, server
/// busy) is retried with the same batch, so it is not an error: it becomes
/// [SyncState.uploadRetry], which says why changes are still waiting.
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
  final retry = uploadError == null || stuck != null
      ? null
      : (upload ?? uploadError).toString();
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
    uploadRetry: retry,
  );
}

/// The synchronized store on PowerSync (cloud sync S5.2, uploads in S5.3).
///
/// Opening is asynchronous, but the [database] is usable at once: its
/// queries wait until PowerSync and Drift are ready. Repositories queue their
/// own upload batches (`SyncQueue`), so there are no capture triggers.
class PowerSyncStore implements SyncedStore {
  PowerSyncStore._(
    this._identity,
    this.spaceId,
    this._client,
    this._powerSyncUrl,
    this._directory,
  ) {
    database = SyncedDatabase(DatabaseConnection.delayed(_openConnection()));
    unawaited(_start());
  }

  /// Opens the store of [identity]'s space [spaceId] and starts downloading
  /// it. [powerSyncUrl] may be empty (a build without it): the store then
  /// never connects. [directory] holds the store's file on native platforms;
  /// the app's documents folder unless given (tests).
  factory PowerSyncStore.open(
    SignedIn identity,
    String spaceId, {
    required SupabaseClient client,
    required String powerSyncUrl,
    Future<String> Function()? directory,
  }) => PowerSyncStore._(identity, spaceId, client, powerSyncUrl, directory);

  final Future<String> Function()? _directory;

  final SignedIn _identity;

  @override
  final String spaceId;
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
  StreamSubscription<bool>? _listedSubscription;
  final _subscriptions = <ps.SyncStreamSubscription>[];
  _SupabaseConnector? _connector;
  bool _closed = false;

  /// Whether this store's space is in its downloaded spaces list. A first
  /// download can finish before a membership granted moments earlier reaches
  /// sync (shared spaces C0, finding 2), so the store only counts as synced
  /// once its own space is listed.
  bool _spaceListed = false;

  @override
  late final SyncedDatabase database;

  Future<DatabaseConnection> _openConnection() async {
    final name = syncedDatabaseNameFor(_identity.userId, spaceId);
    final sync = ps.PowerSyncDatabase(
      schema: const ps.Schema([]),
      path: syncedStorePath(
        name,
        kIsWeb ? '' : await (_directory ?? documentsDirectory)(),
      ),
      sqliteOptions: syncedSqliteOptions(),
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
      // PowerSync skips a status equal to the last one, so a retry failing
      // the same way sends no event: refresh when the record changes.
      final connector = _connector = _SupabaseConnector(
        _client,
        _powerSyncUrl,
        _identity,
        spaceId,
        onUploadFailureChanged: () => _onStatus(sync.currentStatus),
      );
      final listed = Completer<void>();
      _listedSubscription = _watchSpaceListed().listen((isListed) {
        _spaceListed = isListed;
        if (isListed && !listed.isCompleted) listed.complete();
        _onStatus(sync.currentStatus);
      });
      _statusSubscription = sync.statusStream.listen(_onStatus);
      // The spaces list, and this space's records. The automatic stream
      // (fundly_user_data) is for apps 1.2.x and stays off.
      _subscriptions
        ..add(await sync.syncStream('fundly_spaces').subscribe())
        ..add(
          await sync.syncStream('fundly_space_data', {
            'space_id': spaceId,
          }).subscribe(),
        );
      if (_closed) return;
      await sync.connect(
        connector: connector,
        options: const ps.SyncOptions(includeDefaultStreams: false),
      );
      if (firstDownload) {
        for (final subscription in _subscriptions) {
          await subscription.waitForFirstSync();
        }
        await listed.future;
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

  Stream<bool> _watchSpaceListed() => database
      .customSelect(
        'SELECT EXISTS (SELECT 1 FROM spaces WHERE id = ?) AS listed',
        variables: [Variable.withString(spaceId)],
        readsFrom: {database.syncedSpaces},
      )
      .watchSingle()
      .map((row) => row.read<bool>('listed'));

  void _onStatus(ps.SyncStatus status) {
    _emit(
      syncStateFor(
        connected: status.connected,
        connecting: status.connecting,
        hasSynced: (status.hasSynced ?? false) && _spaceListed,
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

  Future<void>? _closing;

  /// Closing twice returns the same future, so a caller can wait until the
  /// store's files are free (to delete them, shared spaces C3).
  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    await _statusSubscription?.cancel();
    await _listedSubscription?.cancel();
    // Released, as PowerSync asks (shared spaces C0, finding 5); the store
    // is closed, so nothing downloads for this space until it opens again.
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
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
  _SupabaseConnector(
    this._client,
    this._endpoint,
    this._identity,
    this._spaceId, {
    required this.onUploadFailureChanged,
  });

  final SupabaseClient _client;
  final String _endpoint;
  final SignedIn _identity;
  final String _spaceId;

  /// Called when [lastUploadFailure] changes.
  final void Function() onUploadFailureChanged;

  /// Why the most recent failed upload failed, or null when that failure
  /// was not a [SyncUploadException]. Kept here because the web sync worker
  /// passes the error back only as text (see [syncStateFor]). Not cleared
  /// while an attempt runs or after a success: [syncStateFor] ignores it
  /// once PowerSync reports no upload error.
  SyncUploadException? lastUploadFailure;

  void _recordFailure(SyncUploadException? failure) {
    if (failure?.code == lastUploadFailure?.code &&
        failure?.outcome == lastUploadFailure?.outcome) {
      return;
    }
    lastUploadFailure = failure;
    onUploadFailureChanged();
  }

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
    try {
      // Never upload one user's changes with another user's token.
      if (_client.auth.currentSession?.user.id != _identity.userId) {
        throw const SyncUploadException(UploadOutcome.transient, 'signed_out');
      }
      final apply = supabaseApplyBatch(
        _client,
        userId: _identity.userId,
        spaceId: _spaceId,
      );
      while (await uploadNextBatch(database, apply)) {}
    } on SyncUploadException catch (failure) {
      _recordFailure(failure);
      rethrow;
    } on Object {
      _recordFailure(null);
      rethrow;
    }
  }
}
