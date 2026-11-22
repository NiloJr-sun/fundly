import 'dart:async';
import 'dart:io';

import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/batch_uploader.dart';
import 'package:fundly/core/sync/dataset_initializer.dart';
import 'package:fundly/core/sync/powersync_store.dart';
import 'package:fundly/core/sync/sync_queue.dart';
import 'package:fundly/core/sync/synced_database.dart';
import 'package:fundly/features/categories/data/synced_category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The upload queue on the real PowerSync SDK (this machine's SQLite).
void main() {
  group('on PowerSync', () {
    late Directory directory;
    late ps.PowerSyncDatabase sync;
    late SyncedDatabase database;

    setUp(() async {
      directory = Directory.systemTemp.createTempSync('fundly_ps_');
      sync = ps.PowerSyncDatabase(
        schema: const ps.Schema([]),
        path: '${directory.path}/store.db',
      );
      await sync.initialize();
      database = SyncedDatabase(SqliteAsyncDriftConnection(sync));
      await database.customSelect('SELECT 1').get();
      await sync.updateSchema(syncedRawSchema);
    });

    tearDown(() async {
      await database.close();
      await sync.close();
      directory.deleteSync(recursive: true);
    });

    Future<String> addCategory(String name) async =>
        (await SyncedCategoryRepository(
          database,
        ).create(name: name, kind: CategoryKind.spending)).id;

    test('a write queues one batch that uploads exactly as queued', () async {
      final id = await addCategory('Gifts');
      final sent = <(String, Map<String, dynamic>)>[];
      expect(
        await uploadNextBatch(sync, (batch, operations) async {
          sent.add((batch, operations));
        }),
        isTrue,
      );
      expect(
        await uploadNextBatch(sync, (_, _) async => fail('empty')),
        isFalse,
      );
      final (batchId, operations) = sent.single;
      expect(batchId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(operations, {
        'version': 1,
        'items': [
          {
            'operation': 'category.create',
            'id': id,
            'data': {
              'name': 'Gifts',
              'kind': 'spending',
              'plan_group': 'spending',
            },
          },
        ],
      });
    });

    test('a failed upload stays queued and is retried unchanged', () async {
      await addCategory('Gifts');
      await addCategory('Travel');
      final attempts = <(String, Map<String, dynamic>)>[];
      for (final error in const [
        SocketException('offline'),
        PostgrestException(message: 'revision_conflict', code: 'P0001'),
      ]) {
        await expectLater(
          uploadNextBatch(sync, (batch, operations) async {
            attempts.add((batch, operations));
            throw error;
          }),
          throwsA(isA<SyncUploadException>()),
        );
      }
      expect(attempts, hasLength(2));
      expect(attempts.first.$1, attempts.last.$1);
      expect(attempts.first.$2, attempts.last.$2);
      // The oldest stays first: later batches wait behind it.
      final names = <Object?>[];
      while (await uploadNextBatch(sync, (_, operations) async {
        final item = (operations['items'] as List).single as Map;
        names.add((item['data'] as Map)['name']);
      })) {}
      expect(names, ['Gifts', 'Travel']);
    });

    test('the pending count follows the queue', () async {
      final counts = <int>[];
      final subscription = sync
          .watch(
            'SELECT count(*) AS pending FROM ps_crud',
            triggerOnTables: const {'ps_crud'},
          )
          .listen((rows) => counts.add(rows.first['pending'] as int));
      await pumpEventQueue();
      await addCategory('Gifts');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await uploadNextBatch(sync, (_, _) async {});
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();
      expect(counts.first, 0);
      expect(counts, contains(1));
      expect(counts.last, 0);
    });

    test('defaults are requested once, only for an empty dataset', () async {
      expect(await initializeDatasetIfEmpty(database), isTrue);
      final sent = <Map<String, dynamic>>[];
      await uploadNextBatch(
        sync,
        (_, operations) async => sent.add(operations),
      );
      final item = (sent.single['items'] as List).single as Map;
      expect(item['operation'], 'dataset.initialize');
      expect(item.keys, unorderedEquals(['operation', 'id']));
      await addCategory('Gifts');
      expect(await initializeDatasetIfEmpty(database), isFalse);
    });
  });

  group('classifying upload errors (SYNC_PROTOCOL.md)', () {
    UploadOutcome outcome(Object error) => classifyUploadError(error).outcome;
    PostgrestException server(String code, [String message = 'x']) =>
        PostgrestException(message: message, code: code);

    test('no answer or a busy server is temporary', () {
      expect(
        outcome(const SocketException('offline')),
        UploadOutcome.transient,
      );
      expect(outcome(TimeoutException('slow')), UploadOutcome.transient);
      for (final code in [
        '40001',
        '40P01',
        '55P03',
        '57014',
        '57P01',
        '53300',
        '08006',
        '503',
        'PGRST301',
      ]) {
        expect(outcome(server(code)), UploadOutcome.transient, reason: code);
      }
      expect(
        outcome(server('28000', 'authentication_required')),
        UploadOutcome.transient,
      );
    });

    test('domain errors and invalid requests are final rejections', () {
      final conflict = classifyUploadError(
        const PostgrestException(
          message: 'revision_conflict',
          code: 'P0001',
          details: '{"index": 0, "current_revision": "3"}',
        ),
      );
      expect(conflict.outcome, UploadOutcome.rejected);
      expect(conflict.code, 'revision_conflict');
      expect(conflict.detail, contains('current_revision'));
      expect(conflict.isStuck, isTrue);
      expect(
        outcome(server('22023', 'invalid_request')),
        UploadOutcome.rejected,
      );
      expect(
        outcome(server('P0001', 'record_deleted')),
        UploadOutcome.rejected,
      );
    });

    test('anything the server cannot process blocks the queue', () {
      expect(
        outcome(server('P0001', 'unsupported_operation')),
        UploadOutcome.blocked,
      );
      expect(
        outcome(server('P0001', 'batch_key_reused')),
        UploadOutcome.blocked,
      );
      expect(outcome(server('42501')), UploadOutcome.blocked);
      expect(outcome(server('PGRST202')), UploadOutcome.blocked);
    });
  });

  test('a queued envelope is protocol 1 with decimal strings', () {
    expect(
      const SyncOperation(
        'transaction.update',
        'id',
        expectedRevision: 9007199254740993,
        data: {'amount_minor': '1'},
      ).toJson(),
      {
        'operation': 'transaction.update',
        'id': 'id',
        'expected_revision': '9007199254740993',
        'data': {'amount_minor': '1'},
      },
    );
  });
}
