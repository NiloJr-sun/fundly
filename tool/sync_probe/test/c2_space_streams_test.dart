// Shared spaces C2.1: the repository's sync config with a second space
// (docs/SHARED_SPACES_C2_PLAN.md). Runs against the LOCAL stack with
// self-hosted PowerSync (tool/sync_probe/cloud/fundly-local), and later
// against the hosted services (C2.4). Skipped unless
// FUNDLY_TEST_{A,B}_{EMAIL,PASSWORD} are set. From tool/sync_probe:
//
//   cloud/fundly-local/up.sh
//   set -a; . cloud/fundly-local/.env.local; set +a
//   FUNDLY_CHECK_CONFIG=cloud/fundly-local/config.local.json \
//     flutter test test/c2_space_streams_test.dart
//
// Spaces cannot be deleted before C3, so each test user reuses one fixed
// space ("C2 check", id derived from the user); the records written here are
// deleted at the end. Credentials and tokens are never printed.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'fundly_stream_test.dart' show fundlyStreamSchema;

final _environment = Platform.environment;
const _credentialNames = [
  'FUNDLY_TEST_A_EMAIL',
  'FUNDLY_TEST_A_PASSWORD',
  'FUNDLY_TEST_B_EMAIL',
  'FUNDLY_TEST_B_PASSWORD',
];

/// The five record tables plus the two space tables of `fundly_spaces`.
final _schema = ps.Schema([
  ...fundlyStreamSchema.tables,
  const ps.Table('spaces', [
    ps.Column.text('name'),
    ps.Column.text('personal_of'),
    ps.Column.text('created_by'),
    ps.Column.text('created_at'),
    ps.Column.text('updated_at'),
    ps.Column.integer('revision'),
  ]),
  const ps.Table('space_members', [
    ps.Column.text('space_id'),
    ps.Column.text('user_id'),
    ps.Column.text('role'),
    ps.Column.text('created_at'),
    ps.Column.text('updated_at'),
  ]),
]);

class _Connector extends ps.PowerSyncBackendConnector {
  _Connector(this.endpoint, this.client);
  final String endpoint;
  final SupabaseClient client;

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async =>
      ps.PowerSyncCredentials(
        endpoint: endpoint,
        token: client.auth.currentSession!.accessToken,
      );

  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {}
}

class _User {
  _User(this.client);
  final SupabaseClient client;
  String get id => client.auth.currentUser!.id;

  Future<Map<String, dynamic>> write(
    List<Map<String, Object?>> items, {
    String? space,
  }) async => await client.rpc(
    'fundly_apply_operations',
    params: {
      'batch_id': const Uuid().v4(),
      'operations': {'version': 1, 'items': items, 'space_id': ?space},
    },
  ) as Map<String, dynamic>;

  /// Account ids in [space] as the server holds them.
  Future<Set<String>> serverAccounts(String space) async => {
    for (final row
        in await client.from('accounts').select('id').eq('space_id', space))
      row['id'] as String,
  };
}

Future<Set<String>> _ids(ps.PowerSyncDatabase database, String table) async => {
  for (final row in await database.getAll('SELECT id FROM $table'))
    row['id'] as String,
};

void main() {
  final missing = _credentialNames.where(
    (name) => (_environment[name] ?? '').isEmpty,
  );
  final skip = missing.isEmpty
      ? null
      : 'Live check: set ${_credentialNames.join(', ')}';

  test(
    'the old stream carries only Personal; each space store only its space',
    () async {
      final config = jsonDecode(
        File(_environment['FUNDLY_CHECK_CONFIG'] ?? 'config.local.json')
            .readAsStringSync(),
      ) as Map<String, Object?>;
      final endpoint = config['POWERSYNC_URL']! as String;
      Future<_User> signIn(String prefix) async {
        final client = SupabaseClient(
          config['SUPABASE_URL']! as String,
          config['SUPABASE_PUBLISHABLE_KEY']! as String,
        );
        await client.auth.signInWithPassword(
          email: _environment['${prefix}_EMAIL']!,
          password: _environment['${prefix}_PASSWORD']!,
        );
        return _User(client);
      }

      final a = await signIn('FUNDLY_TEST_A');
      final b = await signIn('FUNDLY_TEST_B');
      final space = const Uuid().v5(Namespace.url.value, 'fundly-c2:${a.id}');
      await a.client.rpc(
        'fundly_create_space',
        params: {'space_id': space, 'name': 'C2 check'},
      );

      final tag = const Uuid().v4().substring(0, 8);
      final personalAccount = const Uuid().v4();
      final spaceAccount = const Uuid().v4();
      Map<String, Object?> create(String id, String name) => {
        'operation': 'account.create',
        'id': id,
        'data': {
          'name': name,
          'type': 'savingsCash',
          'entered_opening_amount_minor': '0',
        },
      };
      await a.write([create(personalAccount, 'C2 personal $tag')]);
      await a.write([create(spaceAccount, 'C2 space $tag')], space: space);

      final opened = <(ps.PowerSyncDatabase, Directory)>[];
      Future<ps.PowerSyncDatabase> open(
        _User user, {
        String? subscribeTo,
      }) async {
        final directory = await Directory.systemTemp.createTemp('fundly-c2-');
        final database = ps.PowerSyncDatabase(
          schema: _schema,
          path: '${directory.path}/store.sqlite',
        );
        opened.add((database, directory));
        await database.initialize();
        if (subscribeTo == null) {
          // As apps 1.2.x: the automatic stream only.
          await database.connect(connector: _Connector(endpoint, user.client));
          await database.waitForFirstSync().timeout(
            const Duration(seconds: 60),
          );
          return database;
        }
        // As app 1.3.0: no automatic stream; the spaces list and one space.
        final spaces = await database.syncStream('fundly_spaces').subscribe();
        final data = await database.syncStream('fundly_space_data', {
          'space_id': subscribeTo,
        }).subscribe();
        await database.connect(
          connector: _Connector(endpoint, user.client),
          options: const ps.SyncOptions(includeDefaultStreams: false),
        );
        await spaces.waitForFirstSync().timeout(const Duration(seconds: 60));
        await data.waitForFirstSync().timeout(const Duration(seconds: 60));
        return database;
      }

      try {
        final legacy = await open(a);
        expect(
          await _ids(legacy, 'accounts'),
          await a.serverAccounts(a.id),
          reason: 'the automatic stream carries exactly Personal',
        );
        expect(await _ids(legacy, 'accounts'), isNot(contains(spaceAccount)));
        expect(await _ids(legacy, 'spaces'), isEmpty);

        final personal = await open(a, subscribeTo: a.id);
        expect(await _ids(personal, 'accounts'), await a.serverAccounts(a.id));
        expect(await _ids(personal, 'spaces'), containsAll([a.id, space]));

        final second = await open(a, subscribeTo: space);
        expect(await _ids(second, 'accounts'), await a.serverAccounts(space));
        expect(await _ids(second, 'accounts'), contains(spaceAccount));
        expect(
          await _ids(second, 'accounts'),
          isNot(contains(personalAccount)),
        );
        expect(
          await second.getAll(
            'SELECT role FROM space_members WHERE space_id = ? AND user_id = ?',
            [space, a.id],
          ),
          [
            {'role': 'owner'},
          ],
        );

        final outsider = await open(b, subscribeTo: space);
        expect(await _ids(outsider, 'accounts'), isEmpty);
        expect(await _ids(outsider, 'spaces'), isNot(contains(space)));
        expect(await _ids(outsider, 'spaces'), isNot(contains(a.id)));
      } finally {
        for (final (database, directory) in opened) {
          await database.disconnectAndClear();
          await database.close();
          await directory.delete(recursive: true);
        }
        for (final (id, target) in [
          (personalAccount, null),
          (spaceAccount, space),
        ]) {
          await a.write([
            {
              'operation': 'account.set_archived',
              'id': id,
              'expected_revision': '1',
              'data': {'archived': true},
            },
            {'operation': 'account.delete', 'id': id, 'expected_revision': '2'},
          ], space: target);
        }
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
