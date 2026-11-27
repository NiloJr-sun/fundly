import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/sync/batch_uploader.dart';
import 'package:fundly/core/sync/dataset_initializer.dart';
import 'package:fundly/core/sync/powersync_store.dart';
import 'package:fundly/core/sync/sync_queue.dart';
import 'package:fundly/core/sync/sync_rejections.dart';
import 'package:fundly/core/sync/synced_database.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/data/synced_account_repository.dart';
import 'package:fundly/features/accounts/data/synced_custom_bank_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/data/synced_category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/transactions/data/synced_transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
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
        PostgrestException(message: 'unsupported_operation', code: 'P0001'),
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

    group('refused changes (S5.4)', () {
      const conflict = PostgrestException(
        message: 'revision_conflict',
        code: 'P0001',
        details: '{"index": 0, "current_revision": "3"}',
      );
      final refusedAt = DateTime.utc(2026, 11, 22, 8);

      Future<List<SyncRejection>> log() => database.watchRejections().first;

      Future<int> queued() async =>
          (await sync.get('SELECT count(*) AS n FROM ps_crud'))['n'] as int;

      test('a refusal is logged and later changes still upload', () async {
        final gifts = await addCategory('Gifts');
        await addCategory('Travel');
        final sent = <String>[];
        Future<void> apply(
          String batch,
          Map<String, dynamic> operations,
        ) async {
          final item = (operations['items'] as List).single as Map;
          if ((item['data'] as Map)['name'] == 'Gifts') throw conflict;
          sent.add((item['data'] as Map)['name'] as String);
        }

        while (await uploadNextBatch(sync, apply, clock: () => refusedAt)) {}

        expect(sent, ['Travel']);
        expect(await queued(), 0);
        final rejection = (await log()).single;
        expect(rejection.kind, RejectionKind.rejected);
        expect(rejection.code, 'revision_conflict');
        expect(jsonDecode(rejection.detail!), {
          'index': 0,
          'current_revision': '3',
        });
        expect(rejection.items.single['operation'], 'category.create');
        expect(rejection.labels, {gifts: 'Gifts'});
        expect(rejection.rejectedAt, refusedAt);
        expect(rejection.causedBy, isNull);
      });

      test('changes relying on a refused create are never sent', () async {
        final accounts = SyncedAccountRepository(database);
        final transactions = SyncedTransactionRepository(database);
        final wallet = await accounts.create(
          name: 'Wallet',
          type: AccountType.savingsCash,
          enteredOpeningAmount: const Money.zero('PHP'),
        );
        final lunch = await transactions.create(
          TransactionDraft(
            type: TransactionType.inflow,
            amount: const Money(minorUnits: 25000, currencyCode: 'PHP'),
            date: CalendarDate(2026, 11, 20),
            payee: 'Refund',
            destinationAccountId: wallet.id,
          ),
        );
        await transactions.update(
          lunch.id,
          TransactionDraft(
            type: TransactionType.inflow,
            amount: const Money(minorUnits: 30000, currencyCode: 'PHP'),
            date: CalendarDate(2026, 11, 20),
            payee: 'Refund',
            destinationAccountId: wallet.id,
          ),
        );
        final unrelated = await addCategory('Gifts');
        final sent = <String>[];
        while (await uploadNextBatch(sync, (batch, operations) async {
          final item = (operations['items'] as List).single as Map;
          if (item['operation'] == 'account.create') {
            throw const PostgrestException(
              message: 'name_taken',
              code: 'P0001',
            );
          }
          sent.add(item['id'] as String);
        })) {}

        expect(sent, [unrelated]);
        final entries = (await log()).reversed.toList();
        expect(entries.map((r) => r.kind), [
          RejectionKind.rejected,
          RejectionKind.dependencyRejected,
          RejectionKind.dependencyRejected,
        ]);
        expect(entries[0].code, 'name_taken');
        expect(entries[1].causedBy, entries[0].batchId);
        // The edit names the refused account too, the first refusal it
        // relied on.
        expect(entries[2].causedBy, entries[0].batchId);
        expect(entries[1].code, isNull);
        expect(entries[1].labels[wallet.id], 'Wallet');
      });

      test('a batch refused twice is logged once', () async {
        await addCategory('Gifts');
        final batch = (await sync.getNextCrudTransaction())!.crud.single;
        // As if the app was killed after logging, before the queue moved on.
        await recordRejection(
          sync,
          batchId: batch.id,
          envelope: batch.opData!,
          kind: RejectionKind.rejected,
          code: 'revision_conflict',
          now: refusedAt,
        );
        await uploadNextBatch(sync, (_, _) async => throw conflict);
        expect(await log(), hasLength(1));
        expect(await queued(), 0);
      });

      test('a batch accepted on a later attempt leaves the log', () async {
        await addCategory('Gifts');
        final batch = (await sync.getNextCrudTransaction())!.crud.single;
        await recordRejection(
          sync,
          batchId: batch.id,
          envelope: batch.opData!,
          kind: RejectionKind.rejected,
          code: 'revision_conflict',
          now: refusedAt,
        );
        await uploadNextBatch(sync, (_, _) async {});
        expect(await log(), isEmpty);
      });

      test('dismissing removes entries', () async {
        await addCategory('Gifts');
        await addCategory('Travel');
        while (await uploadNextBatch(sync, (_, _) async => throw conflict)) {}
        final entries = await log();
        expect(entries, hasLength(2));
        await database.dismissRejection(entries.first.batchId);
        expect(await log(), hasLength(1));
        await database.dismissAllRejections();
        expect(await log(), isEmpty);
      });
    });

    group('restoring server state after a refusal (S5.4)', () {
      // Feeds download checkpoints straight into PowerSync's sync client,
      // as the service would; the five rows below are the server's state.
      var lastOp = 0;
      var uploadsCompleted = false;
      var checkpointRequests = 0;
      final serverRows = <Map<String, Object?>>[];
      setUp(() {
        lastOp = 0;
        uploadsCompleted = false;
        serverRows.clear();
      });

      Future<String> control(
        String operation, [
        Object? payload,
      ]) async => sync.writeTransaction(
        (tx) async =>
            '${(await tx.execute('SELECT powersync_control(?, ?) AS r', [operation, payload])).first['r']}',
      );

      Map<String, Object?> category(String id, String name) => {
        'id': id,
        'name': name,
        'kind': 'spending',
        'plan_group': 'spending',
        'is_archived': 0,
        'is_plan_archived': 0,
        'is_plan_deleted': 0,
        'linked_account_id': null,
        'created_at': '2026-11-16 09:30:00+00',
        'updated_at': '2026-11-16 09:30:00+00',
        'revision': 1,
      };

      /// What PowerSync does once the queue is empty after uploads, refused
      /// or not: the next download asks the service for a write checkpoint
      /// and applies nothing until a checkpoint includes it.
      void requestWriteCheckpoint() => uploadsCompleted = true;

      /// Sends a checkpoint holding [serverRows] plus [newRows], including the
      /// requested write checkpoint; returns whether PowerSync applied it.
      Future<bool> download([
        List<Map<String, Object?>> newRows = const [],
        String table = 'categories',
      ]) async {
        final operations = [
          for (final row in newRows)
            {
              'op_id': '${++lastOp}',
              'op': 'PUT',
              'object_type': table,
              'object_id': row['id'],
              'checksum': 1,
              'subkey': null,
              'data': jsonEncode(row),
            },
        ];
        serverRows.addAll(newRows);
        await control(
          'start',
          jsonEncode({
            'parameters': <String, Object?>{},
            'schema': syncedRawSchema.toJson(),
          }),
        );
        String? writeCheckpoint;
        if (uploadsCompleted) {
          // The service's answer to the request, which the next checkpoint
          // then carries.
          uploadsCompleted = false;
          writeCheckpoint = '${++checkpointRequests}';
          await control('target_checkpoint_request_id', writeCheckpoint);
        }
        await control(
          'line_text',
          jsonEncode({
            'checkpoint': {
              'last_op_id': '$lastOp',
              'write_checkpoint': ?writeCheckpoint,
              'buckets': [
                {
                  'bucket': 'user',
                  'checksum': serverRows.length,
                  'priority': 3,
                  'count': serverRows.length,
                },
              ],
            },
          }),
        );
        if (operations.isNotEmpty) {
          await control(
            'line_text',
            jsonEncode({
              'data': {
                'bucket': 'user',
                'has_more': false,
                'after': null,
                'next_after': '$lastOp',
                'data': operations,
              },
            }),
          );
        }
        final result = await control(
          'line_text',
          jsonEncode({
            'checkpoint_complete': {'last_op_id': '$lastOp'},
          }),
        );
        await control('stop');
        return result.contains('DidCompleteSync');
      }

      Map<String, Object?> account(String id, String name) => {
        'id': id,
        'name': name,
        'type': 'savingsCash',
        'opening_balance_minor': 0,
        'currency_code': 'PHP',
        'is_archived': 0,
        'custom_type_id': null,
        'is_budget_account': 0,
        'created_at': '2026-11-16 09:30:00+00',
        'updated_at': '2026-11-16 09:30:00+00',
        'revision': 1,
      };

      Map<String, Object?> transaction(
        String id, {
        required String type,
        required int amountMinor,
        required String payee,
        String? sourceAccountId,
        String? destinationAccountId,
      }) => {
        'id': id,
        'type': type,
        'amount_minor': amountMinor,
        'currency_code': 'PHP',
        'date': '2026-11-10',
        'payee': payee,
        'category_id': null,
        'source_account_id': sourceAccountId,
        'destination_account_id': destinationAccountId,
        'note': '',
        'created_at': '2026-11-16 09:30:00+00',
        'updated_at': '2026-11-16 09:30:00+00',
        'revision': 1,
      };

      Future<void> refuseAll() async {
        while (await uploadNextBatch(sync, (_, _) async {
          throw const PostgrestException(
            message: 'revision_conflict',
            code: 'P0001',
          );
        })) {}
      }

      Future<Map<String, String>> names() async => {
        for (final row in await sync.getAll(
          'SELECT id, name FROM categories ORDER BY name',
        ))
          row['id'] as String: row['name'] as String,
      };

      test('refused insert, edit and delete are undone', () async {
        const kept = '00000000-0000-4000-8000-000000000001';
        const renamed = '00000000-0000-4000-8000-000000000002';
        const removed = '00000000-0000-4000-8000-000000000003';
        expect(
          await download([
            category(kept, 'Fuel'),
            category(renamed, 'Rent'),
            category(removed, 'Internet'),
          ]),
          isTrue,
        );
        final categories = SyncedCategoryRepository(database);
        final added = await addCategory('Gifts');
        await categories.rename(renamed, 'Housing');
        await categories.delete(removed);
        expect(await names(), {
          kept: 'Fuel',
          added: 'Gifts',
          renamed: 'Housing',
        });

        while (await uploadNextBatch(sync, (_, _) async {
          throw const PostgrestException(
            message: 'revision_conflict',
            code: 'P0001',
          );
        })) {}
        requestWriteCheckpoint();
        // Nothing new on the server, as after a refusal.
        expect(await download(), isTrue);

        expect(await names(), {
          kept: 'Fuel',
          renamed: 'Rent',
          removed: 'Internet',
        });
        expect(await database.watchRejections().first, hasLength(3));
      });

      test('custom banks download; a refused rename and delete are named '
          'and undone (banks)', () async {
        const coop = '00000000-0000-4000-8000-000000000021';
        expect(
          await download([
            {
              'id': coop,
              'name': 'Town Coop',
              'created_at': '2026-11-16 09:30:00+00',
              'updated_at': '2026-11-16 09:30:00+00',
              'revision': 1,
            },
          ], 'custom_banks'),
          isTrue,
        );
        final banks = SyncedCustomBankRepository(database);
        expect((await banks.watchAll().first).single.name, 'Town Coop');

        await banks.rename(coop, 'Coop Bank');
        await refuseAll();
        requestWriteCheckpoint();
        expect(await download(), isTrue);
        expect((await banks.watchAll().first).single.name, 'Town Coop');

        await banks.delete(coop);
        expect(await banks.watchAll().first, isEmpty);
        await refuseAll();
        requestWriteCheckpoint();
        expect(await download(), isTrue);
        expect((await banks.watchAll().first).single.name, 'Town Coop');

        final entries = await database.watchRejections().first;
        expect(
          {for (final e in entries) e.items.single['operation']: e.labels},
          {
            'bank.update': {coop: 'Coop Bank'},
            'bank.delete': {coop: 'Town Coop'},
          },
        );
      });

      group('a refused delete still names its record (F.1)', () {
        test('from the download log, for a category', () async {
          const removed = '00000000-0000-4000-8000-000000000003';
          await download([category(removed, 'Internet')]);
          await SyncedCategoryRepository(database).delete(removed);
          await refuseAll();

          final rejection = (await database.watchRejections().first).single;
          expect(rejection.items.single['operation'], 'category.delete');
          expect(rejection.labels, {removed: 'Internet'});
        });

        test('by payee, or by type, amount and date without one', () async {
          const wallet = '00000000-0000-4000-8000-000000000011';
          const savings = '00000000-0000-4000-8000-000000000012';
          const groceries = '00000000-0000-4000-8000-000000000021';
          const move = '00000000-0000-4000-8000-000000000022';
          await download([
            account(wallet, 'Wallet'),
            account(savings, 'Savings'),
          ], 'accounts');
          await download([
            transaction(
              groceries,
              type: 'spending',
              amountMinor: 50000,
              payee: 'Groceries',
              sourceAccountId: wallet,
            ),
            transaction(
              move,
              type: 'transfer',
              amountMinor: 260000,
              payee: '',
              sourceAccountId: wallet,
              destinationAccountId: savings,
            ),
          ], 'transactions');
          final transactions = SyncedTransactionRepository(database);
          await transactions.delete(groceries);
          await transactions.delete(move);
          await refuseAll();

          final entries = (await database.watchRejections().first).reversed
              .toList();
          expect(entries, hasLength(2));
          expect(entries[0].labels, {groceries: 'Groceries'});
          expect(entries[0].transactionFacts(groceries), isNull);
          expect(entries[1].labels.containsKey(move), isFalse);
          final facts = entries[1].transactionFacts(move)!;
          expect(facts.type, 'transfer');
          expect(facts.amountMinor, 260000);
          expect(facts.currencyCode, 'PHP');
          expect(facts.date, '2026-11-10');
        });

        test('but not one the server never had', () async {
          final categories = SyncedCategoryRepository(database);
          final added = await addCategory('Gifts');
          await categories.delete(added);
          await refuseAll();

          final entries = await database.watchRejections().first;
          expect(entries, hasLength(2));
          for (final entry in entries) {
            expect(entry.labels.containsKey(added), isFalse);
          }
        });
      });

      test('without a refusal, optimistic rows are left alone', () async {
        const kept = '00000000-0000-4000-8000-000000000001';
        await download([category(kept, 'Fuel')]);
        final added = await addCategory('Gifts');
        // Accepted, but the server's copy has not arrived in this checkpoint.
        await uploadNextBatch(sync, (_, _) async {});
        requestWriteCheckpoint();
        expect(await download(), isTrue);
        expect(await names(), {kept: 'Fuel', added: 'Gifts'});
      });

      test('nothing is restored while changes still wait to upload', () async {
        const renamed = '00000000-0000-4000-8000-000000000002';
        await download([category(renamed, 'Rent')]);
        await SyncedCategoryRepository(database).rename(renamed, 'Housing');
        await addCategory('Gifts');
        // The rename is refused; the new category still waits.
        await uploadNextBatch(sync, (_, _) async {
          throw const PostgrestException(
            message: 'revision_conflict',
            code: 'P0001',
          );
        });
        expect(await download(), isFalse);
        expect((await names()).values, containsAll(['Housing', 'Gifts']));
        // Once the queue is empty, the next download restores the rename.
        await uploadNextBatch(sync, (_, _) async {});
        requestWriteCheckpoint();
        expect(await download(), isTrue);
        expect((await names())[renamed], 'Rent');
      });
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

    for (final firstDownload in [true, false]) {
      test(
        'missing Personal bootstraps after ${firstDownload ? 'first' : 'previously completed empty'} download',
        () async {
          expect(
            await initializePersonalAfterDownload(
              database,
              userId: 'new-user',
              firstDownload: firstDownload,
            ),
            isTrue,
          );
          final sent = <Map<String, dynamic>>[];
          await uploadNextBatch(
            sync,
            (_, operations) async => sent.add(operations),
          );
          final item = (sent.single['items'] as List).single as Map;
          expect(item['operation'], 'dataset.initialize');
        },
      );
    }

    test(
      'reopening listed Personal does not reseed an empty dataset',
      () async {
        await database.customInsert(
          'INSERT INTO spaces (id, name, personal_of, created_by, created_at, '
          "updated_at, revision) VALUES ('user', 'Personal', 'user', 'user', "
          "'2026-11-24', '2026-11-24', 1)",
        );
        expect(
          await initializePersonalAfterDownload(
            database,
            userId: 'user',
            firstDownload: false,
          ),
          isFalse,
        );
        expect(
          await database.customSelect('SELECT * FROM ps_crud').get(),
          isEmpty,
        );
      },
    );

    test('a viewer never asks for the defaults (C3)', () async {
      Future<void> member(String user, String role) => database.customInsert(
        'INSERT INTO space_members (id, space_id, user_id, role, created_at, '
        "updated_at) VALUES (?, 's1', ?, ?, '2026-11-24', '2026-11-24')",
        variables: [
          Variable.withString('s1:$user'),
          Variable.withString(user),
          Variable.withString(role),
        ],
      );
      await member('viewer-user', 'viewer');
      await member('editor-user', 'editor');

      expect(
        await initializeDatasetIfEmpty(
          database,
          spaceId: 's1',
          userId: 'viewer-user',
        ),
        isFalse,
      );
      expect(
        await database.customSelect('SELECT * FROM ps_crud').get(),
        isEmpty,
      );
      expect(
        await initializeDatasetIfEmpty(
          database,
          spaceId: 's1',
          userId: 'editor-user',
        ),
        isTrue,
      );
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
      expect(conflict.isStuck, isFalse);
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
      expect(
        classifyUploadError(server('P0001', 'unsupported_operation')).isStuck,
        isTrue,
      );
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
