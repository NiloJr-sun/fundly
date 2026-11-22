import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/dataset_import.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/cloud_data_resetter.dart';
import 'package:fundly/features/categories/data/default_categories.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_synced_store.dart';

const user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

const seen = BackupCounts(
  customAccountTypes: 1,
  accounts: 4,
  categories: 12,
  transactions: 131,
  monthlyPlans: 2,
);

Map<String, Object?> serverResult() => {
  'version': 1,
  'import_id': 'ignored',
  'mode': 'replace',
  'counts': {
    'custom_account_types': 0,
    'accounts': 0,
    'categories': 9,
    'transactions': 0,
    'monthly_plans': 0,
  },
};

typedef Call = ({String userId, String importId, Map<String, Object?> request});

void main() {
  late List<Call> calls;
  late List<Object> failures;
  late List<Duration> waits;
  late int ids;

  setUp(() {
    calls = [];
    failures = [];
    waits = [];
    ids = 0;
  });

  CloudDataResetter resetter() => CloudDataResetter(
    importDataset:
        ({required userId, required importId, required request}) async {
          calls.add((userId: userId, importId: importId, request: request));
          if (failures.isNotEmpty) throw failures.removeAt(0);
          return serverResult();
        },
    userId: user.userId,
    newId: () => 'id-${ids++}',
    wait: (duration) async => waits.add(duration),
  );

  test('sends one replace request that leaves only the defaults', () async {
    final after = await resetter().resetAll(expected: seen);

    expect(after, freshAccountCounts);
    final call = calls.single;
    expect(call.userId, user.userId);
    expect(call.importId, 'id-0');
    final request = call.request;
    expect(request['version'], 1);
    expect(request['mode'], 'replace');
    expect(request['expected'], {
      'custom_account_types': 1,
      'accounts': 4,
      'categories': 12,
      'transactions': 131,
      'monthly_plans': 2,
    });
    final dataset = request['dataset']! as Map<String, Object?>;
    for (final table in [
      'custom_account_types',
      'accounts',
      'transactions',
      'monthly_plans',
    ]) {
      expect(dataset[table], isEmpty, reason: table);
    }
    final categories = dataset['categories']! as List<Object?>;
    expect(categories, hasLength(defaultCategories.length));
    expect(categories.first, {
      'id': 'id-1',
      'name': 'Rent',
      'kind': 'spending',
      'is_archived': false,
      'is_plan_archived': false,
      'is_plan_deleted': false,
      'plan_group': 'spending',
      'linked_account_id': null,
    });
    expect(
      [
        for (final category in categories.cast<Map<String, Object?>>())
          (name: category['name'], kind: category['kind']),
      ],
      [
        for (final category in defaultCategories)
          (name: category.name, kind: category.kind.name),
      ],
    );
    expect(
      {for (final c in categories.cast<Map<String, Object?>>()) c['id']},
      hasLength(defaultCategories.length),
      reason: 'every category gets its own fresh ID',
    );
  });

  test('a lost response is resent with the same ID and body', () async {
    failures = [Exception('socket closed'), Exception('timeout')];

    final after = await resetter().resetAll(expected: seen);

    expect(after, freshAccountCounts);
    expect(calls, hasLength(3));
    expect(calls.map((call) => call.importId).toSet(), {'id-0'});
    expect(calls[2].request, calls[0].request);
    expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
  });

  test('gives up after three attempts as unreachable', () async {
    failures = [Exception('a'), Exception('b'), Exception('c')];

    await expectLater(
      resetter().resetAll(expected: seen),
      throwsA(
        isA<CloudResetException>().having(
          (e) => e.problem,
          'problem',
          CloudResetProblem.unreachable,
        ),
      ),
    );
    expect(calls, hasLength(3));
  });

  test('an expired session is retried like a network failure', () async {
    failures = [
      const PostgrestException(
        message: 'authentication_required',
        code: '28000',
      ),
    ];

    expect(await resetter().resetAll(expected: seen), freshAccountCounts);
    expect(calls, hasLength(2));
  });

  test('changed counts mean another device wrote; never retried', () async {
    failures = [
      const PostgrestException(
        message: 'dataset_changed',
        code: 'P0001',
        details: '{"current": {}}',
      ),
    ];

    await expectLater(
      resetter().resetAll(expected: seen),
      throwsA(
        isA<CloudResetException>().having(
          (e) => e.problem,
          'problem',
          CloudResetProblem.datasetChanged,
        ),
      ),
    );
    expect(calls, hasLength(1));
  });

  for (final (code, message) in [
    ('P0001', 'invalid_import'),
    ('P0001', 'record_id_unavailable'),
    ('22023', 'invalid_request'),
  ]) {
    test('$message is refused with its code and never retried', () async {
      failures = [PostgrestException(message: message, code: code)];

      await expectLater(
        resetter().resetAll(expected: seen),
        throwsA(
          isA<CloudResetException>()
              .having((e) => e.problem, 'problem', CloudResetProblem.refused)
              .having((e) => e.code, 'code', message),
        ),
      );
      expect(calls, hasLength(1));
    });
  }

  test('watchSyncedCounts counts every synced record', () async {
    final store = FakeSyncedStore(user);
    addTearDown(store.close);
    await store.download({
      'custom_account_types': [SyncedRows.customType('t1', 'E-wallet')],
      'accounts': [
        SyncedRows.account('a1', 'BDO'),
        SyncedRows.account('a2', 'GCash', customTypeId: 't1'),
      ],
      'categories': [SyncedRows.category('c1', 'Food')],
      'transactions': [
        SyncedRows.transaction('x1', categoryId: 'c1', sourceAccountId: 'a1'),
      ],
      'monthly_plans': [SyncedRows.plan('p1', categoryId: 'c1')],
    });

    expect(
      await watchSyncedCounts(store.database).first,
      const BackupCounts(
        customAccountTypes: 1,
        accounts: 2,
        categories: 1,
        transactions: 1,
        monthlyPlans: 1,
      ),
    );
  });

  group('cloudDataResetterProvider', () {
    Future<Map<String, Object?>> noImport({
      required String userId,
      required String importId,
      required Map<String, Object?> request,
    }) async => const {};

    test('is available signed in with the cloud configuration', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: user),
          ),
          importDatasetProvider.overrideWithValue(noImport),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(cloudDataResetterProvider), isNotNull);
    });

    test('is null signed out or without the cloud configuration', () {
      final signedOut = ProviderContainer(
        overrides: [importDatasetProvider.overrideWithValue(noImport)],
      );
      final noCloud = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: user),
          ),
        ],
      );
      addTearDown(signedOut.dispose);
      addTearDown(noCloud.dispose);

      expect(signedOut.read(cloudDataResetterProvider), isNull);
      expect(noCloud.read(cloudDataResetterProvider), isNull);
    });
  });
}
