// Shared spaces C3.1: sharing through the repository's sync config
// (docs/SHARED_SPACES_C3_PLAN.md). Two users: A owns a space and invites B;
// B's store gets the space and its members' names; B's writes reach A;
// removal takes the space off B's store; deleting it takes it off both.
// Runs against the LOCAL stack (tool/sync_probe/cloud/fundly-local) and,
// in C3.4, the hosted services. Skipped unless FUNDLY_TEST_{A,B}_* are set:
//
//   set -a; . cloud/fundly-local/.env.local; set +a
//   FUNDLY_CHECK_CONFIG=cloud/fundly-local/config.local.json \
//     flutter test test/c3_sharing_streams_test.dart
//
// The space is created and deleted by the test. Credentials, tokens and
// invite secrets are never printed.
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
    ps.Column.text('email'),
    ps.Column.text('display_name'),
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

Future<Set<String>> _ids(ps.PowerSyncDatabase database, String table) async => {
  for (final row in await database.getAll('SELECT id FROM $table'))
    row['id'] as String,
};

Future<void> _until(Future<bool> Function() condition, String label) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out: $label');
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

void main() {
  final missing = _credentialNames.where(
    (name) => (_environment[name] ?? '').isEmpty,
  );
  final skip = missing.isEmpty
      ? null
      : 'Live check: set ${_credentialNames.join(', ')}';

  test(
    'invite, accept, write, remove and delete reach both devices',
    () async {
      final config = jsonDecode(
        File(_environment['FUNDLY_CHECK_CONFIG'] ?? 'config.local.json')
            .readAsStringSync(),
      ) as Map<String, Object?>;
      final endpoint = config['POWERSYNC_URL']! as String;
      Future<SupabaseClient> signIn(String prefix) async {
        final client = SupabaseClient(
          config['SUPABASE_URL']! as String,
          config['SUPABASE_PUBLISHABLE_KEY']! as String,
        );
        await client.auth.signInWithPassword(
          email: _environment['${prefix}_EMAIL']!,
          password: _environment['${prefix}_PASSWORD']!,
        );
        return client;
      }

      final a = await signIn('FUNDLY_TEST_A');
      final b = await signIn('FUNDLY_TEST_B');
      final aId = a.auth.currentUser!.id;
      final bId = b.auth.currentUser!.id;
      final bEmail = b.auth.currentUser!.email!.toLowerCase();
      final space = const Uuid().v4();
      final tag = space.substring(0, 8);
      await a.rpc(
        'fundly_create_space',
        params: {'space_id': space, 'name': 'C3 check $tag'},
      );

      Future<String> invite() async =>
          (await a.rpc(
                'fundly_create_invite',
                params: {'space_id': space, 'email': bEmail, 'role': 'editor'},
              ) as Map)['secret']
              as String;
      Future<void> write(SupabaseClient client, Map<String, Object?> item) =>
          client.rpc(
            'fundly_apply_operations',
            params: {
              'batch_id': const Uuid().v4(),
              'operations': {
                'version': 1,
                'space_id': space,
                'items': [item],
              },
            },
          );

      final ownerAccount = const Uuid().v4();
      await write(a, {
        'operation': 'account.create',
        'id': ownerAccount,
        'data': {
          'name': 'Joint $tag',
          'type': 'savingsCash',
          'entered_opening_amount_minor': '0',
        },
      });

      final opened = <(ps.PowerSyncDatabase, Directory)>[];
      Future<ps.PowerSyncDatabase> open(SupabaseClient client) async {
        final directory = await Directory.systemTemp.createTemp('fundly-c3-');
        final database = ps.PowerSyncDatabase(
          schema: _schema,
          path: '${directory.path}/store.sqlite',
        );
        opened.add((database, directory));
        await database.initialize();
        await database.syncStream('fundly_spaces').subscribe();
        await database.syncStream('fundly_space_data', {
          'space_id': space,
        }).subscribe();
        await database.connect(
          connector: _Connector(endpoint, client),
          options: const ps.SyncOptions(includeDefaultStreams: false),
        );
        await database.waitForFirstSync().timeout(const Duration(seconds: 60));
        return database;
      }

      var deleted = false;
      try {
        final aStore = await open(a);
        await _until(
          () async => (await _ids(aStore, 'accounts')).contains(ownerAccount),
          'the owner has the space',
        );

        // B: no access before accepting.
        final bStore = await open(b);
        expect(await _ids(bStore, 'accounts'), isEmpty);
        expect(await _ids(bStore, 'spaces'), isNot(contains(space)));

        await b.rpc('fundly_accept_invite', params: {'secret': await invite()});
        await _until(
          () async => (await _ids(bStore, 'accounts')).contains(ownerAccount),
          'the new member downloads the space',
        );
        final owner = await bStore.get(
          'SELECT role, email, display_name FROM space_members '
          'WHERE space_id = ? AND user_id = ?',
          [space, aId],
        );
        expect(owner['role'], 'owner');
        expect(owner['email'], a.auth.currentUser!.email!.toLowerCase());

        // B's write reaches A.
        final memberAccount = const Uuid().v4();
        await write(b, {
          'operation': 'account.create',
          'id': memberAccount,
          'data': {
            'name': 'Member $tag',
            'type': 'savingsCash',
            'entered_opening_amount_minor': '0',
          },
        });
        await _until(
          () async => (await _ids(aStore, 'accounts')).contains(memberAccount),
          'the member\'s write reaches the owner',
        );

        // Removal takes the space off B's store, not A's.
        await a.rpc(
          'fundly_remove_member',
          params: {'space_id': space, 'user_id': bId},
        );
        await _until(
          () async =>
              (await _ids(bStore, 'accounts')).isEmpty &&
              !(await _ids(bStore, 'spaces')).contains(space),
          'the removed member loses the space',
        );
        expect(await _ids(aStore, 'accounts'), contains(memberAccount));

        // Back in, then the owner deletes the space: it leaves both stores.
        await b.rpc('fundly_accept_invite', params: {'secret': await invite()});
        await _until(
          () async => (await _ids(bStore, 'accounts')).isNotEmpty,
          'the member is back',
        );
        await a.rpc(
          'fundly_delete_space',
          params: {'space_id': space, 'name': 'C3 check $tag'},
        );
        deleted = true;
        for (final store in [aStore, bStore]) {
          await _until(
            () async =>
                (await _ids(store, 'accounts')).isEmpty &&
                !(await _ids(store, 'spaces')).contains(space),
            'a deleted space leaves every device',
          );
        }
      } finally {
        for (final (database, directory) in opened) {
          await database.disconnectAndClear();
          await database.close();
          await directory.delete(recursive: true);
        }
        if (!deleted) {
          await a.rpc(
            'fundly_delete_space',
            params: {'space_id': space, 'name': 'C3 check $tag'},
          );
        }
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
