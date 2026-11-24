// Shared spaces C0 prototype (docs/SHARED_SPACES_C0_PLAN.md): one PowerSync
// store per (user, space), as the app would keep them. Used by the C0 checks
// and the C0 probe screen. Talks only to the LOCAL C0 environment.
import 'dart:async';
import 'dart:convert';

import 'package:powersync/powersync.dart' as ps;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Fundly's production project; C0 refuses any configuration that names it.
const _productionRef = 'jiiuukimazvcxautvmya';

/// Public endpoints of the local C0 environment.
class C0Config {
  const C0Config({
    required this.supabaseUrl,
    required this.publishableKey,
    required this.powerSyncUrl,
  });

  /// From `--dart-define-from-file=cloud/c0/config.local.json`.
  factory C0Config.fromEnvironment() => C0Config(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    powerSyncUrl: const String.fromEnvironment('POWERSYNC_URL'),
  );

  final String supabaseUrl;
  final String publishableKey;
  final String powerSyncUrl;

  bool get isComplete =>
      supabaseUrl.isNotEmpty &&
      publishableKey.isNotEmpty &&
      powerSyncUrl.isNotEmpty;

  /// The same local stack under `localhost`. In a browser, Supabase auth
  /// shares one session between every client whose host starts the same way
  /// (its broadcast key), so a second signed-in test user in the same page
  /// needs a different host name.
  C0Config withLocalhost() => C0Config(
    supabaseUrl: supabaseUrl.replaceFirst('//127.0.0.1:', '//localhost:'),
    publishableKey: publishableKey,
    powerSyncUrl: powerSyncUrl,
  );

  /// Throws unless this points at the local C0 environment.
  void checkLocal() {
    bool local(String url) =>
        url.startsWith('http://127.0.0.1:') ||
        url.startsWith('http://localhost:');
    if (supabaseUrl.contains(_productionRef) ||
        !local(supabaseUrl) ||
        !local(powerSyncUrl)) {
      throw StateError('C0 runs only against the local C0 environment');
    }
  }
}

/// Mirrors cloud/c0/powersync/sync-config.yaml, plus a local-only log of
/// refused uploads (what Fundly keeps in `sync_rejections`).
const c0Schema = ps.Schema([
  ps.Table('c0_spaces', [
    ps.Column.text('name'),
    ps.Column.text('created_by'),
    ps.Column.text('created_at'),
    ps.Column.text('updated_at'),
  ]),
  ps.Table('c0_space_members', [
    ps.Column.text('space_id'),
    ps.Column.text('user_id'),
    ps.Column.text('role'),
    ps.Column.text('created_at'),
    ps.Column.text('updated_at'),
  ]),
  ps.Table('c0_entries', [
    ps.Column.text('space_id'),
    ps.Column.text('label'),
    ps.Column.integer('amount_minor'),
    ps.Column.text('created_by'),
    ps.Column.text('updated_by'),
    ps.Column.text('created_at'),
    ps.Column.text('updated_at'),
    ps.Column.integer('revision'),
  ]),
  ps.Table.localOnly('c0_refused', [
    ps.Column.text('batch_id'),
    ps.Column.text('code'),
    ps.Column.text('operations'),
  ]),
]);

/// Server error codes that mean "never going to apply": log and move on.
const _refusalCodes = {'42501', '40001', '23505', '23514', '22023'};

/// A signed-in C0 test user and the server calls the checks use.
class C0User {
  C0User(this.name, this.client);
  final String name;
  final SupabaseClient client;

  static Future<C0User> signIn(
    C0Config config,
    String name,
    String email,
    String password,
  ) async {
    config.checkLocal();
    final client = SupabaseClient(
      config.supabaseUrl,
      config.publishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: true),
    );
    await client.auth.signInWithPassword(email: email, password: password);
    return C0User(name, client);
  }

  String get id => client.auth.currentUser!.id;
  String get token => client.auth.currentSession!.accessToken;

  Future<void> createSpace(String space, String name) =>
      client.rpc('c0_create_space', params: {'p_id': space, 'p_name': name});

  Future<void> setMember(String space, C0User user, String role) => client.rpc(
    'c0_set_member',
    params: {'p_space': space, 'p_user': user.id, 'p_role': role},
  );

  Future<void> removeMember(String space, C0User user) => client.rpc(
    'c0_remove_member',
    params: {'p_space': space, 'p_user': user.id},
  );

  Future<void> deleteSpace(String space) =>
      client.rpc('c0_delete_space', params: {'p_space': space});

  Future<void> put(String space, String entry, String label) => client.rpc(
    'c0_apply_batch',
    params: {
      'p_batch_id': const Uuid().v4(),
      'p_space_id': space,
      'p_ops': [
        {
          'op': 'PUT',
          'id': entry,
          'data': {'label': label, 'amount_minor': '100'},
        },
      ],
    },
  );
}

/// Uploads each local transaction as one `c0_apply_batch` into the store's
/// space. With [logRefusals], a refused batch is logged in `c0_refused` and
/// completed, as Fundly's uploader does; without it the error propagates and
/// PowerSync keeps retrying (the queue stays stuck).
class _Connector extends ps.PowerSyncBackendConnector {
  _Connector(
    this.endpoint,
    this.user,
    this.space,
    this.storeName, {
    required this.logRefusals,
  });
  final String endpoint;
  final C0User user;
  final String space;
  final String storeName;
  final bool logRefusals;

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async =>
      ps.PowerSyncCredentials(endpoint: endpoint, token: user.token);

  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;
    final operations = [
      for (final entry in transaction.crud)
        if (entry.table == 'c0_entries')
          {
            'op': entry.op.json,
            'id': entry.id,
            'data': entry.opData,
            if (entry.previousValues != null) 'old': entry.previousValues,
          },
    ];
    final batchId = const Uuid().v5(
      Namespace.url.value,
      '$storeName:${transaction.transactionId}',
    );
    try {
      await user.client.rpc(
        'c0_apply_batch',
        params: {
          'p_batch_id': batchId,
          'p_space_id': space,
          'p_ops': operations,
        },
      );
    } on PostgrestException catch (error) {
      if (!logRefusals || !_refusalCodes.contains(error.code)) rethrow;
      await database.execute(
        'INSERT INTO c0_refused (id, batch_id, code, operations) '
        'VALUES (uuid(), ?, ?, ?)',
        [batchId, error.code, jsonEncode(operations)],
      );
    }
    await transaction.complete();
  }
}

/// The store name the app would use for [user]'s copy of [space].
String c0StoreName(C0User user, String space) => 'c0_${user.id}_$space';

/// One device store: one user's copy of one space.
class C0Store {
  C0Store._(this.database, this.user, this.space, this._connector);
  final ps.PowerSyncDatabase database;
  final C0User user;
  final String space;
  final _Connector _connector;
  ps.SyncStreamSubscription? _subscription;

  /// Opens (or reopens) the store at [path] without connecting.
  static Future<C0Store> open(
    String path,
    C0Config config,
    C0User user,
    String space, {
    bool logRefusals = true,
  }) async {
    config.checkLocal();
    final database = ps.PowerSyncDatabase(
      schema: c0Schema,
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
    await database.initialize();
    return C0Store._(
      database,
      user,
      space,
      _Connector(
        config.powerSyncUrl,
        user,
        space,
        c0StoreName(user, space),
        logRefusals: logRefusals,
      ),
    );
  }

  /// Subscribes to this store's space, connects and waits for its first sync.
  /// Finding (C0.2): the first sync can finish before a membership granted
  /// moments earlier has reached PowerSync, so for a member the store is ready
  /// only once its own space appears in `c0_my_spaces`.
  Future<void> sync({bool member = true}) async {
    final subscription = _subscription ??= await database.syncStream(
      'c0_space_entries',
      {'space_id': space},
    ).subscribe();
    await connect();
    await subscription.waitForFirstSync().timeout(const Duration(seconds: 60));
    if (member) {
      await waitUntil(
        () async => (await ids('c0_spaces')).contains(space),
        'space visible to a new member\'s store',
      );
    }
  }

  Future<void> connect() => database.connect(connector: _connector);
  Future<void> disconnect() => database.disconnect();

  Future<Set<String>> ids(String table, [String where = '1']) async => {
    for (final row in await database.getAll(
      'SELECT id FROM $table WHERE $where',
    ))
      row['id'] as String,
  };

  /// Closes the store; [clear] also deletes its data (signing out, leaving).
  Future<void> close({bool clear = false}) async {
    _subscription?.unsubscribe();
    _subscription = null;
    if (clear) {
      await database.disconnectAndClear();
    } else {
      await database.disconnect();
    }
    await database.close();
  }
}

/// Polls [condition] until it holds; returns how long it took (logged, for
/// the C0 findings). Throws a [TimeoutException] after [timeout].
Future<Duration> waitUntil(
  Future<bool> Function() condition,
  String label, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final started = DateTime.now();
  while (!await condition()) {
    if (DateTime.now().difference(started) > timeout) {
      throw TimeoutException('Timed out: $label', timeout);
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  final took = DateTime.now().difference(started);
  // ignore: avoid_print
  print('  $label: ${took.inMilliseconds} ms');
  return took;
}
