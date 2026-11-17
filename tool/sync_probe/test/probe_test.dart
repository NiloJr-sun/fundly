import 'package:flutter_test/flutter_test.dart';
import 'package:fundly_sync_probe/probe_database.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:uuid/uuid.dart';

import 'scratch_native.dart' if (dart.library.js_interop) 'scratch_web.dart';

void main() {
  for (final raw in [false, true]) {
    group(raw ? 'raw tables' : 'managed views', () {
      late ProbeStore store;
      late String path;
      setUp(() async {
        path = await scratchPath();
        store = await ProbeStore.open(path, raw: raw);
      });
      tearDown(() async {
        await store.close();
        await removeScratch(path);
      });

      test(
        'UUID parent and child share one durable CRUD transaction',
        () async {
          final parent = const Uuid().v4();
          final child = const Uuid().v4();
          await store.drift.createPair(parent, child);
          final queued = (await store.sync.getNextCrudTransaction())!;
          expect(queued.crud, hasLength(2));
          expect(queued.crud.map((e) => e.id), [parent, child]);
          expect(queued.crud.last.opData!['parent_id'], parent);
          expect(queued.transactionId, isNotNull);
          expect(queued.crud.map((e) => e.transactionId).toSet(), hasLength(1));
        },
      );

      test(
        'offline data and unacknowledged upload survive reopening',
        () async {
          await store.drift.createPair('parent', 'child');
          final queued = (await store.sync.getNextCrudTransaction())!;
          final ids = queued.crud.map((e) => e.clientId).toList();
          // No complete(): models a network failure or rejected upload.
          await store.close();
          store = await ProbeStore.open(path, raw: raw);
          expect(
            await store.drift.select(store.drift.probeEntries).get(),
            hasLength(1),
          );
          final retry = (await store.sync.getNextCrudTransaction())!;
          expect(retry.crud.map((e) => e.clientId), ids);
          await retry.complete();
          expect(await store.sync.getNextCrudTransaction(), isNull);
        },
      );

      test(
        'failed multi-record transaction rolls back rows and queue',
        () async {
          await expectLater(
            store.drift.transaction(() async {
              await store.drift.createPair('parent', 'child');
              throw StateError('simulate interrupted workflow');
            }),
            throwsStateError,
          );
          expect(
            await store.drift.select(store.drift.probeParents).get(),
            isEmpty,
          );
          expect(await store.sync.getNextCrudTransaction(), isNull);
        },
      );

      test('Drift watch receives a write through PowerSync API', () async {
        final observed = store.drift
            .select(store.drift.probeParents)
            .watch()
            .firstWhere((rows) => rows.any((row) => row.id == 'external'))
            .timeout(const Duration(seconds: 5));
        await store.sync.execute(
          'INSERT INTO probe_parents (id, name, revision) VALUES (?, ?, ?)',
          ['external', 'SDK write', 1],
        );
        expect((await observed).single.name, 'SDK write');
      });

      test('deletion creates a durable delete operation', () async {
        await store.drift.createPair('parent', 'child');
        await (await store.sync.getNextCrudTransaction())!.complete();
        await (store.drift.delete(
          store.drift.probeEntries,
        )..where((row) => row.id.equals('child'))).go();
        final queued = (await store.sync.getNextCrudTransaction())!;
        expect(queued.crud.single.op, ps.UpdateType.delete);
        expect(queued.crud.single.id, 'child');
      });

      test(
        'revision before an edit is captured for conflict detection',
        () async {
          await store.drift.createPair('parent', 'child');
          await (await store.sync.getNextCrudTransaction())!.complete();
          await store.sync.execute(
            'UPDATE probe_parents SET name = ?, revision = ? WHERE id = ?',
            ['Edited', 2, 'parent'],
          );
          final queued = (await store.sync.getNextCrudTransaction())!;
          expect(queued.crud.single.previousValues!['revision'], 1);
        },
      );

      if (raw) {
        test(
          'Drift schema upgrade retains records and the pending queue',
          () async {
            await store.drift.createPair('parent', 'child');
            final before = (await store.sync.getNextCrudTransaction())!;
            await store.close();
            store = await ProbeStore.open(path, raw: true, version: 2);
            final after = (await store.sync.getNextCrudTransaction())!;
            expect(
              after.crud.map((e) => e.clientId),
              before.crud.map((e) => e.clientId),
            );
            await after.complete();
            await store.sync.execute(
              'UPDATE probe_parents SET local_note = ? WHERE id = ?',
              ['Not synchronized', 'parent'],
            );
            expect(
              (await store.sync.get(
                'SELECT local_note FROM probe_parents',
              ))['local_note'],
              'Not synchronized',
            );
            expect(
              await store.drift.select(store.drift.probeEntries).get(),
              hasLength(1),
            );
            expect(await store.sync.getNextCrudTransaction(), isNull);
          },
        );

        test(
          'deferred foreign key permits child-before-parent in one transaction',
          () async {
            await store.sync.writeLock((tx) async {
              await tx.execute('PRAGMA foreign_keys = ON');
              await tx.writeTransaction((transaction) async {
                await transaction.execute(
                  'INSERT INTO probe_entries (id, parent_id, amount_minor) VALUES (?, ?, ?)',
                  ['child', 'parent', 100],
                );
                await transaction.execute(
                  'INSERT INTO probe_parents (id, name, revision) VALUES (?, ?, ?)',
                  ['parent', 'Created later', 1],
                );
              });
            });
            expect(
              await store.drift.select(store.drift.probeEntries).get(),
              hasLength(1),
            );
          },
        );
      }

      test(
        'CHECK constraints differ between managed views and raw tables',
        () async {
          await store.drift.createPair('parent', 'child');
          final invalid = store.sync.execute(
            'UPDATE probe_entries SET amount_minor = -1 WHERE id = ?',
            ['child'],
          );
          if (raw) {
            await expectLater(invalid, throwsA(isA<Exception>()));
          } else {
            await invalid;
            expect(
              (await store.sync.get(
                'SELECT amount_minor FROM probe_entries',
              ))['amount_minor'],
              -1,
            );
          }
        },
      );

      test(
        'foreign keys are enforced when enabled on the write connection',
        () async {
          await store.sync.writeLock((tx) async {
            await tx.execute('PRAGMA foreign_keys = ON');
            final insert = tx.execute(
              'INSERT INTO probe_entries (id, parent_id, amount_minor) VALUES (?, ?, ?)',
              ['orphan', 'missing', 100],
            );
            if (raw) {
              await expectLater(insert, throwsA(isA<Exception>()));
            } else {
              await insert;
            }
          });
        },
      );
    });
  }
}
