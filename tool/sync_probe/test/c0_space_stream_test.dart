// Shared spaces C0.2 live stream checks (docs/SHARED_SPACES_C0_PLAN.md)
// against the LOCAL C0 environment (tool/sync_probe/cloud/c0). Skipped unless
// C0_TEST_{A,B,C}_{EMAIL,PASSWORD} are set. Run from tool/sync_probe:
//
//   cloud/c0/up.sh
//   set -a; . cloud/c0/.env.local; set +a
//   flutter test test/c0_space_stream_test.dart
//
// Endpoints come from cloud/c0/config.local.json (or C0_CHECK_CONFIG).
// Credentials and tokens are never printed. Every space a check creates is
// deleted afterwards. Stores are managed-view PowerSync databases, one per
// (user, space), each subscribed to its own space as the app would be.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final _environment = Platform.environment;
const _credentialNames = [
  'C0_TEST_A_EMAIL',
  'C0_TEST_A_PASSWORD',
  'C0_TEST_B_EMAIL',
  'C0_TEST_B_PASSWORD',
  'C0_TEST_C_EMAIL',
  'C0_TEST_C_PASSWORD',
];
const _productionRef = 'jiiuukimazvcxautvmya';

/// Mirrors cloud/c0/powersync/sync-config.yaml, plus a local-only log of
/// refused uploads (what Fundly keeps in `sync_rejections`).
const _schema = ps.Schema([
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

class _User {
  _User(this.name, this.client);
  final String name;
  final SupabaseClient client;

  String get id => client.auth.currentUser!.id;
  String get token => client.auth.currentSession!.accessToken;

  Future<void> createSpace(String space, String name) =>
      client.rpc('c0_create_space', params: {'p_id': space, 'p_name': name});

  Future<void> setMember(String space, _User user, String role) => client.rpc(
    'c0_set_member',
    params: {'p_space': space, 'p_user': user.id, 'p_role': role},
  );

  Future<void> removeMember(String space, _User user) => client.rpc(
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
  final _User user;
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

/// One device store for one user's view of one space.
class _Store {
  _Store._(this.database, this.directory, this.connector);
  late final ps.SyncStreamSubscription subscription;
  final ps.PowerSyncDatabase database;
  final Directory directory;
  final _Connector connector;

  static Future<_Store> open(
    String endpoint,
    _User user,
    String space, {
    bool logRefusals = true,
    bool member = true,
  }) async {
    final storeName = 'c0_${user.id}_$space';
    final directory = await Directory.systemTemp.createTemp('fundly-c0-');
    final database = ps.PowerSyncDatabase(
      schema: _schema,
      path: '${directory.path}/$storeName.sqlite',
    );
    await database.initialize();
    final connector = _Connector(
      endpoint,
      user,
      space,
      storeName,
      logRefusals: logRefusals,
    );
    final store = _Store._(database, directory, connector);
    final subscription = store.subscription = await database.syncStream(
      'c0_space_entries',
      {'space_id': space},
    ).subscribe();
    await store.connect();
    await subscription.waitForFirstSync().timeout(const Duration(seconds: 60));
    // Finding: the first sync can finish before a membership granted moments
    // earlier has reached PowerSync, so it starts empty. A member's store is
    // ready once its own space appears in c0_my_spaces.
    if (member) {
      await _until(
        () async => (await store.ids('c0_spaces')).contains(space),
        'space visible to a new member\'s store',
      );
    }
    return store;
  }

  Future<void> connect() => database.connect(connector: connector);
  Future<void> disconnect() => database.disconnect();

  Future<Set<String>> ids(String table, [String where = '1']) async => {
    for (final row in await database.getAll(
      'SELECT id FROM $table WHERE $where',
    ))
      row['id'] as String,
  };

  Future<void> close() async {
    subscription.unsubscribe();
    await database.disconnectAndClear();
    await database.close();
    await directory.delete(recursive: true);
  }
}

Future<Duration> _until(
  Future<bool> Function() condition,
  String label, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final started = DateTime.now();
  while (!await condition()) {
    if (DateTime.now().difference(started) > timeout) {
      fail('Timed out: $label');
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  final took = DateTime.now().difference(started);
  // Timings feed the C0 findings.
  // ignore: avoid_print
  print('  $label: ${took.inMilliseconds} ms');
  return took;
}

/// Checks that [condition] stays true for [period].
Future<void> _staysFor(
  Future<bool> Function() condition,
  String label, {
  Duration period = const Duration(seconds: 8),
}) async {
  final until = DateTime.now().add(period);
  while (DateTime.now().isBefore(until)) {
    expect(await condition(), isTrue, reason: label);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

void main() {
  final missing = _credentialNames.where(
    (name) => (_environment[name] ?? '').isEmpty,
  );
  final skip = missing.isEmpty
      ? null
      : 'Live C0 check: set ${_credentialNames.join(', ')}';

  late String endpoint;
  late _User a, b, c;
  final spaces = <String>[];
  final stores = <_Store>[];

  Future<String> newSpace(String name) async {
    final space = const Uuid().v4();
    await a.createSpace(space, name);
    spaces.add(space);
    return space;
  }

  Future<_Store> open(
    _User user,
    String space, {
    bool logRefusals = true,
    bool member = true,
  }) async {
    final store = await _Store.open(
      endpoint,
      user,
      space,
      logRefusals: logRefusals,
      member: member,
    );
    stores.add(store);
    return store;
  }

  setUpAll(() async {
    if (skip != null) return;
    final config = jsonDecode(
      File(_environment['C0_CHECK_CONFIG'] ?? 'cloud/c0/config.local.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    final url = config['SUPABASE_URL']! as String;
    endpoint = config['POWERSYNC_URL']! as String;
    if (url.contains(_productionRef) || !url.startsWith('http://127.0.0.1:')) {
      fail('Refusing: C0 checks run only against the local C0 environment');
    }
    Future<_User> signIn(String letter) async {
      final client = SupabaseClient(
        url,
        config['SUPABASE_PUBLISHABLE_KEY']! as String,
      );
      await client.auth.signInWithPassword(
        email: _environment['C0_TEST_${letter}_EMAIL']!,
        password: _environment['C0_TEST_${letter}_PASSWORD']!,
      );
      return _User(letter, client);
    }

    a = await signIn('A');
    b = await signIn('B');
    c = await signIn('C');
    expect({a.id, b.id, c.id}, hasLength(3));
  });

  tearDown(() async {
    for (final store in stores) {
      await store.close();
    }
    stores.clear();
    for (final space in spaces) {
      await a.deleteSpace(space);
    }
    spaces.clear();
  });

  const timeout = Timeout(Duration(minutes: 3));

  test(
    '1-2: each store holds only its space; an outsider gets nothing',
    () async {
      final s1 = await newSpace('C0 S1');
      final s2 = await newSpace('C0 S2');
      final e1 = const Uuid().v4(), e2 = const Uuid().v4();
      await a.put(s1, e1, 'S1 entry');
      await a.put(s2, e2, 'S2 entry');

      final aS1 = await open(a, s1);
      final aS2 = await open(a, s2);
      expect(await aS1.ids('c0_entries'), {e1});
      expect(await aS2.ids('c0_entries'), {e2});
      expect(await aS1.ids('c0_spaces'), {s1, s2}, reason: 'my spaces stream');

      final cS1 = await open(c, s1, member: false);
      expect(await cS1.ids('c0_entries'), isEmpty);
      expect(await cS1.ids('c0_spaces'), isEmpty);
      expect(await cS1.ids('c0_space_members'), isEmpty);

      final e3 = const Uuid().v4();
      await a.put(s1, e3, 'S1 later');
      await _until(
        () async => (await aS1.ids('c0_entries')).contains(e3),
        'new entry reaches the owner',
      );
      await _staysFor(
        () async => (await cS1.ids('c0_entries')).isEmpty,
        'outsider still has nothing',
        period: const Duration(seconds: 3),
      );
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    '4-5: an editor syncs both ways; a viewer reads but is refused',
    () async {
      final s1 = await newSpace('C0 roles');
      final e1 = const Uuid().v4();
      await a.put(s1, e1, 'Owner entry');
      final aS1 = await open(a, s1);

      await a.setMember(s1, b, 'editor');
      final bS1 = await open(b, s1);
      expect(await bS1.ids('c0_entries'), {e1});
      expect(await bS1.ids('c0_space_members'), hasLength(2));

      final fromB = const Uuid().v4();
      await bS1.database.execute(
        'INSERT INTO c0_entries (id, space_id, label, amount_minor, revision) '
        'VALUES (?, ?, ?, ?, 1)',
        [fromB, s1, 'Editor entry', 250],
      );
      await _until(
        () async => (await aS1.ids('c0_entries')).contains(fromB),
        'editor write reaches the owner',
      );
      final row = await aS1.database.get(
        'SELECT created_by FROM c0_entries WHERE id = ?',
        [fromB],
      );
      expect(row['created_by'], b.id);

      await a.setMember(s1, b, 'viewer');
      await _until(
        () async =>
            (await bS1.ids('c0_space_members', "role = 'viewer'")).isNotEmpty,
        'role change reaches the member',
      );
      final refused = const Uuid().v4();
      await bS1.database.execute(
        'INSERT INTO c0_entries (id, space_id, label, amount_minor, revision) '
        'VALUES (?, ?, ?, ?, 1)',
        [refused, s1, 'Viewer entry', 300],
      );
      await _until(
        () async => (await bS1.ids('c0_refused')).isNotEmpty,
        'viewer write refused and logged',
      );
      final log = await bS1.database.get(
        'SELECT code, operations FROM c0_refused',
      );
      expect(log['code'], '42501');
      expect(log['operations'] as String, contains(refused));
      await _until(
        () async => !(await bS1.ids('c0_entries')).contains(refused),
        'refused local row reverted',
      );
      expect(await bS1.ids('c0_entries'), containsAll([e1, fromB]));
      expect(await aS1.ids('c0_entries'), isNot(contains(refused)));
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    '6: removing a connected member removes the space from the device',
    () async {
      final s1 = await newSpace('C0 removal');
      await a.put(s1, const Uuid().v4(), 'Shared entry');
      await a.setMember(s1, b, 'editor');
      final bS1 = await open(b, s1);
      expect(await bS1.ids('c0_entries'), hasLength(1));
      expect(await bS1.ids('c0_spaces'), contains(s1));

      await a.removeMember(s1, b);
      await _until(
        () async => (await bS1.ids('c0_entries')).isEmpty,
        'entries removed after removal (connected)',
      );
      await _until(
        () async =>
            (await bS1.ids('c0_spaces')).isEmpty &&
            (await bS1.ids('c0_space_members')).isEmpty,
        'space and members removed (connected)',
      );
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    '7: a member removed while offline loses the space on reconnect',
    () async {
      final s1 = await newSpace('C0 offline removal');
      await a.put(s1, const Uuid().v4(), 'Shared entry');
      await a.setMember(s1, b, 'editor');
      final bS1 = await open(b, s1);
      expect(await bS1.ids('c0_entries'), hasLength(1));

      await bS1.disconnect();
      await a.removeMember(s1, b);
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(
        await bS1.ids('c0_entries'),
        hasLength(1),
        reason: 'still offline',
      );

      await bS1.connect();
      await _until(
        () async =>
            (await bS1.ids('c0_entries')).isEmpty &&
            (await bS1.ids('c0_spaces')).isEmpty,
        'space removed on reconnect',
      );
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    '8: a removed member\'s queued write is refused, kept, and the space '
    'still leaves the device',
    () async {
      final s1 = await newSpace('C0 queued write');
      await a.put(s1, const Uuid().v4(), 'Shared entry');
      await a.setMember(s1, b, 'editor');
      final aS1 = await open(a, s1);
      final bS1 = await open(b, s1);

      await bS1.disconnect();
      final queued = const Uuid().v4();
      await bS1.database.execute(
        'INSERT INTO c0_entries (id, space_id, label, amount_minor, revision) '
        'VALUES (?, ?, ?, ?, 1)',
        [queued, s1, 'Written offline', 400],
      );
      await a.removeMember(s1, b);
      await bS1.connect();

      await _until(
        () async => (await bS1.ids('c0_refused')).isNotEmpty,
        'queued write refused and logged',
      );
      final log = await bS1.database.get(
        'SELECT code, operations FROM c0_refused',
      );
      expect(log['code'], '42501');
      expect(log['operations'] as String, contains(queued));
      await _until(
        () async =>
            (await bS1.ids('c0_entries')).isEmpty &&
            (await bS1.ids('c0_spaces')).isEmpty,
        'space removed after the refusal',
      );
      expect(await aS1.ids('c0_entries'), isNot(contains(queued)));
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    '8b: if a refused upload is retried instead of logged, the queue '
    'blocks and the removed space stays on the device',
    () async {
      final s1 = await newSpace('C0 stuck queue');
      await a.put(s1, const Uuid().v4(), 'Shared entry');
      await a.setMember(s1, b, 'editor');
      final bS1 = await open(b, s1, logRefusals: false);

      await bS1.disconnect();
      await bS1.database.execute(
        'INSERT INTO c0_entries (id, space_id, label, amount_minor, revision) '
        'VALUES (?, ?, ?, ?, 1)',
        [const Uuid().v4(), s1, 'Written offline', 400],
      );
      await a.removeMember(s1, b);
      await bS1.connect();
      await _staysFor(
        () async =>
            (await bS1.ids('c0_entries')).length == 2 &&
            (await bS1.database.getAll('SELECT 1 FROM ps_crud')).isNotEmpty,
        'removed space kept while the queue is stuck',
      );
    },
    skip: skip,
    timeout: timeout,
  );
}
