// S3 live stream isolation check against the hosted Supabase and PowerSync
// projects. Skipped unless FUNDLY_TEST_{A,B}_{EMAIL,PASSWORD} are set, so the
// probe's normal `flutter test` stays offline. Run from tool/sync_probe:
//
//   FUNDLY_TEST_A_EMAIL=... FUNDLY_TEST_A_PASSWORD=... \
//   FUNDLY_TEST_B_EMAIL=... FUNDLY_TEST_B_PASSWORD=... \
//   flutter test test/fundly_stream_test.dart
//
// Endpoints come from the ignored config.local.json (or FUNDLY_CHECK_CONFIG).
// Credentials and tokens are never printed. Fundly's streams download into
// throwaway managed-view databases here; this checks scoping, not app schema.
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
  'FUNDLY_TEST_A_EMAIL',
  'FUNDLY_TEST_A_PASSWORD',
  'FUNDLY_TEST_B_EMAIL',
  'FUNDLY_TEST_B_PASSWORD',
];

const _tables = [
  'custom_account_types',
  'accounts',
  'categories',
  'transactions',
  'monthly_plans',
];

const _audit = [
  ps.Column.text('created_at'),
  ps.Column.text('updated_at'),
  ps.Column.integer('revision'),
];

/// Mirrors powersync/sync-config.yaml column for column.
const fundlyStreamSchema = ps.Schema([
  ps.Table('custom_account_types', [
    ps.Column.text('name'),
    ps.Column.text('base_type'),
    ..._audit,
  ]),
  ps.Table('accounts', [
    ps.Column.text('name'),
    ps.Column.text('type'),
    ps.Column.integer('opening_balance_minor'),
    ps.Column.text('currency_code'),
    ps.Column.integer('is_archived'),
    ps.Column.text('custom_type_id'),
    ps.Column.integer('is_budget_account'),
    ..._audit,
  ]),
  ps.Table('categories', [
    ps.Column.text('name'),
    ps.Column.text('kind'),
    ps.Column.integer('is_archived'),
    ps.Column.integer('is_plan_archived'),
    ps.Column.integer('is_plan_deleted'),
    ps.Column.text('plan_group'),
    ps.Column.text('linked_account_id'),
    ..._audit,
  ]),
  ps.Table('transactions', [
    ps.Column.text('type'),
    ps.Column.integer('amount_minor'),
    ps.Column.text('currency_code'),
    ps.Column.text('date'),
    ps.Column.text('payee'),
    ps.Column.text('category_id'),
    ps.Column.text('source_account_id'),
    ps.Column.text('destination_account_id'),
    ps.Column.text('note'),
    ..._audit,
  ]),
  ps.Table('monthly_plans', [
    ps.Column.text('month'),
    ps.Column.text('category_id'),
    ps.Column.integer('target_amount_minor'),
    ps.Column.integer('assigned_amount_minor'),
    ps.Column.text('currency_code'),
    ..._audit,
  ]),
]);

/// Read-only: this check never uploads local changes.
class _TokenConnector extends ps.PowerSyncBackendConnector {
  _TokenConnector(this.endpoint, this.token);
  final String endpoint;
  final String Function() token;

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async =>
      ps.PowerSyncCredentials(endpoint: endpoint, token: token());

  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {}
}

class _User {
  _User(this.client);
  final SupabaseClient client;

  String get token => client.auth.currentSession!.accessToken;

  Future<void> apply(List<Map<String, Object?>> items) => client.rpc(
    'fundly_apply_operations',
    params: {
      'batch_id': const Uuid().v4(),
      'operations': {'version': 1, 'items': items},
    },
  );

  /// The user's Personal records: what the automatic stream carries. Since
  /// shared spaces C2 a user can read other spaces' records too, which only
  /// the opt-in streams deliver.
  Future<Set<String>> serverIds(String table) async => {
    for (final row
        in await client
            .from(table)
            .select('id')
            .eq('space_id', client.auth.currentUser!.id))
      row['id'] as String,
  };
}

Future<Set<String>> _localIds(
  ps.PowerSyncDatabase database,
  String table,
) async => {
  for (final row in await database.getAll('SELECT id FROM $table'))
    row['id'] as String,
};

Future<(ps.PowerSyncDatabase, Directory)> _open(
  String endpoint,
  String Function() token,
) async {
  final directory = await Directory.systemTemp.createTemp('fundly-s3-stream-');
  final database = ps.PowerSyncDatabase(
    schema: fundlyStreamSchema,
    path: '${directory.path}/stream.sqlite',
  );
  await database.initialize();
  await database.connect(connector: _TokenConnector(endpoint, token));
  return (database, directory);
}

Future<void> _until(Future<bool> Function() condition, String label) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out: $label');
    await Future<void>.delayed(const Duration(milliseconds: 500));
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
    'each user downloads only their own rows',
    () async {
      final config = jsonDecode(
        File(_environment['FUNDLY_CHECK_CONFIG'] ?? 'config.local.json')
            .readAsStringSync(),
      ) as Map<String, Object?>;
      final url = config['SUPABASE_URL']! as String;
      final key = config['SUPABASE_PUBLISHABLE_KEY']! as String;
      final endpoint = config['POWERSYNC_URL']! as String;

      Future<_User> signIn(String prefix) async {
        final client = SupabaseClient(url, key);
        await client.auth.signInWithPassword(
          email: _environment['${prefix}_EMAIL']!,
          password: _environment['${prefix}_PASSWORD']!,
        );
        return _User(client);
      }

      final a = await signIn('FUNDLY_TEST_A');
      final b = await signIn('FUNDLY_TEST_B');
      expect(
        a.client.auth.currentUser!.id,
        isNot(b.client.auth.currentUser!.id),
      );

      final tag = const Uuid().v4().substring(0, 8);
      final id = {
        for (final name in [
          'type',
          'account',
          'category',
          'transaction',
          'plan',
          'later',
          'other',
        ])
          name: const Uuid().v4(),
      };
      final opened = <(ps.PowerSyncDatabase, Directory)>[];
      // Cleanup removes only what was created; one bad item rolls back a batch.
      var createdByA = false, createdByB = false, createdLater = false;
      try {
        await a.apply([
          {
            'operation': 'custom_type.create',
            'id': id['type'],
            'data': {'name': 'S3 stream type $tag', 'base_type': 'savingsCash'},
          },
          {
            'operation': 'account.create',
            'id': id['account'],
            'data': {
              'name': 'S3 stream cash $tag',
              'type': 'savingsCash',
              'entered_opening_amount_minor': '0',
              'custom_type_id': id['type'],
            },
          },
          {
            'operation': 'category.create',
            'id': id['category'],
            'data': {'name': 'S3 stream food $tag', 'kind': 'spending'},
          },
          {
            'operation': 'transaction.create',
            'id': id['transaction'],
            'data': {
              'type': 'spending',
              'amount_minor': '100',
              'date': '2026-11-18',
              'payee': 'S3 stream',
              'source_account_id': id['account'],
              'category_id': id['category'],
            },
          },
          {
            'operation': 'plan.save',
            'id': id['plan'],
            'data': {
              'category_id': id['category'],
              'month': '2026-11',
              'target_amount_minor': null,
              'assigned_amount_minor': '100',
              'previous': null,
            },
          },
        ]);
        createdByA = true;
        await b.apply([
          {
            'operation': 'category.create',
            'id': id['other'],
            'data': {'name': 'S3 stream food $tag', 'kind': 'spending'},
          },
        ]);
        createdByB = true;

        final databaseA = await _open(endpoint, () => a.token);
        final databaseB = await _open(endpoint, () => b.token);
        opened.addAll([databaseA, databaseB]);
        for (final (database, _) in opened) {
          await database.waitForFirstSync().timeout(
            const Duration(seconds: 60),
          );
        }

        for (final table in _tables) {
          final localA = await _localIds(databaseA.$1, table);
          final localB = await _localIds(databaseB.$1, table);
          expect(localA, await a.serverIds(table), reason: 'A $table');
          expect(localB, await b.serverIds(table), reason: 'B $table');
          expect(localA.intersection(localB), isEmpty, reason: table);
        }
        expect(
          await _localIds(databaseA.$1, 'categories'),
          isNot(contains(id['other'])),
        );
        expect(
          await _localIds(databaseB.$1, 'categories'),
          contains(id['other']),
        );
        final downloaded = await databaseA.$1.get(
          'SELECT amount_minor, date FROM transactions WHERE id = ?',
          [id['transaction']],
        );
        expect(downloaded['amount_minor'], 100);
        expect(downloaded['date'], '2026-11-18');

        await a.apply([
          {
            'operation': 'transaction.create',
            'id': id['later'],
            'data': {
              'type': 'spending',
              'amount_minor': '200',
              'date': '2026-11-18',
              'payee': 'S3 later',
              'source_account_id': id['account'],
              'category_id': id['category'],
            },
          },
        ]);
        createdLater = true;
        await _until(
          () async => (await _localIds(
            databaseA.$1,
            'transactions',
          )).contains(id['later']),
          'committed RPC change downloads',
        );
        expect(
          await _localIds(databaseB.$1, 'transactions'),
          isNot(contains(id['later'])),
        );

        // A token with a broken signature must never open a stream.
        final forged = await _open(endpoint, () => '${a.token}x');
        opened.add(forged);
        await Future<void>.delayed(const Duration(seconds: 10));
        expect(forged.$1.currentStatus.hasSynced, isNot(true));
        for (final table in _tables) {
          expect(
            await _localIds(forged.$1, table),
            isEmpty,
            reason: 'forged $table',
          );
        }
      } finally {
        for (final (database, directory) in opened) {
          await database.disconnectAndClear();
          await database.close();
          await directory.delete(recursive: true);
        }
        if (createdByA) {
          await a.apply([
            for (final transaction in [
              id['transaction'],
              if (createdLater) id['later'],
            ])
              {
                'operation': 'transaction.delete',
                'id': transaction,
                'expected_revision': '1',
              },
            {
              'operation': 'plan.save',
              'id': id['plan'],
              'data': {
                'category_id': id['category'],
                'month': '2026-11',
                'target_amount_minor': null,
                'assigned_amount_minor': '0',
                'previous': {'id': id['plan'], 'revision': '1'},
              },
            },
            {
              'operation': 'category.delete',
              'id': id['category'],
              'expected_revision': '1',
            },
            {
              'operation': 'account.set_archived',
              'id': id['account'],
              'expected_revision': '1',
              'data': {'archived': true},
            },
            {
              'operation': 'account.delete',
              'id': id['account'],
              'expected_revision': '2',
            },
            {
              'operation': 'custom_type.delete',
              'id': id['type'],
              'expected_revision': '1',
            },
          ]);
        }
        if (createdByB) {
          await b.apply([
            {
              'operation': 'category.delete',
              'id': id['other'],
              'expected_revision': '1',
            },
          ]);
        }
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
