// Shared spaces C2.2: the real PowerSyncStore with two spaces, against the
// LOCAL stack and self-hosted PowerSync (tool/sync_probe/cloud/fundly-local).
// Skipped unless FUNDLY_TEST_A_EMAIL/PASSWORD and FUNDLY_CHECK_CONFIG are set:
//
//   tool/sync_probe/cloud/fundly-local/up.sh
//   set -a; . tool/sync_probe/cloud/fundly-local/.env.local; set +a
//   FUNDLY_CHECK_CONFIG=tool/sync_probe/cloud/fundly-local/config.local.json \
//     flutter test test/core/sync/space_store_live_test.dart
//
// Refuses anything but a local stack. The space is fixed per test user
// (spaces cannot be deleted before C3); records written here are deleted.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/powersync_store.dart';
import 'package:fundly/core/sync/sync_queue.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spaces/data/space_directory.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final _environment = Platform.environment;

Future<void> _until(Future<bool> Function() condition, String label) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out: $label');
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

void main() {
  final configPath = _environment['FUNDLY_CHECK_CONFIG'] ?? '';
  final skip =
      configPath.isEmpty ||
          (_environment['FUNDLY_TEST_A_EMAIL'] ?? '').isEmpty ||
          (_environment['FUNDLY_TEST_A_PASSWORD'] ?? '').isEmpty
      ? 'Live check: set FUNDLY_CHECK_CONFIG and FUNDLY_TEST_A_*'
      : null;

  test(
    'two spaces in two stores: each downloads and uploads only its own',
    () async {
      final config = jsonDecode(
        File(configPath).readAsStringSync(),
      ) as Map<String, Object?>;
      final url = config['SUPABASE_URL']! as String;
      if (!url.startsWith('http://127.0.0.1:')) {
        fail('This check writes to the server: local stack only');
      }
      final client = SupabaseClient(
        url,
        config['SUPABASE_PUBLISHABLE_KEY']! as String,
      );
      final session = await client.auth.signInWithPassword(
        email: _environment['FUNDLY_TEST_A_EMAIL']!,
        password: _environment['FUNDLY_TEST_A_PASSWORD']!,
      );
      final identity = SignedIn(
        userId: session.user!.id,
        email: session.user!.email ?? '',
      );
      final spaceId = const Uuid().v5(
        Namespace.url.value,
        'fundly-c22:${identity.userId}',
      );
      await SupabaseSpaceService(client)
          .create(spaceId: spaceId, name: 'C2.2 check');
      final directory = await Directory.systemTemp.createTemp('fundly-c22-');
      final stores = <SyncedStore>[];
      Future<SyncedStore> open(String space) async {
        final store = PowerSyncStore.open(
          identity,
          space,
          client: client,
          powerSyncUrl: config['POWERSYNC_URL']! as String,
          directory: () async => directory.path,
        );
        stores.add(store);
        // Synced means: downloaded, and its own space is listed.
        await store
            .watchState()
            .firstWhere((state) => state.hasSynced)
            .timeout(const Duration(seconds: 60));
        final listed = await watchSpaces(store.database, identity.userId).first;
        expect(listed.map((s) => s.id), containsAll({identity.userId, space}));
        return store;
      }

      Future<Set<String>> local(SyncedStore store) async => {
        for (final row
            in await store.database
                .customSelect('SELECT id FROM categories')
                .get())
          row.read<String>('id'),
      };
      Future<Set<String>> server(String space) async => {
        for (final row
            in await client
                .from('categories')
                .select('id')
                .eq('space_id', space))
          row['id'] as String,
      };

      final category = newRecordId();
      try {
        final personal = await open(identity.userId);
        final second = await open(spaceId);
        // A brand-new user's Personal gets its defaults the same way.
        await _until(
          () async =>
              (await local(personal)).length ==
                  (await server(identity.userId)).length &&
              (await server(identity.userId)).isNotEmpty,
          'Personal matches the server',
        );
        expect(await local(personal), await server(identity.userId));
        // A new space gets its default categories just after its first
        // download (queued by the store, then uploaded), as Personal does on
        // a first sign-in.
        await _until(
          () async =>
              (await server(spaceId)).isNotEmpty &&
              (await local(second)).length == (await server(spaceId)).length,
          'the new space has its own default categories, on both sides',
        );
        expect(await local(second), await server(spaceId));
        expect(
          (await local(second)).intersection(await local(personal)),
          isEmpty,
        );

        // A change made in the second space's store uploads into that space.
        await second.database.queue([
          SyncOperation(
            'category.create',
            category,
            data: const {'name': 'C2.2 only here', 'kind': 'spending'},
          ),
        ]);
        await _until(
          () async => (await server(spaceId)).contains(category),
          'upload reaches the second space',
        );
        expect(await server(identity.userId), isNot(contains(category)));
        await _until(
          () async => (await second.watchPendingUploads().first) == 0,
          'queue empties',
        );
        expect(await local(personal), isNot(contains(category)));
      } finally {
        if (stores.length == 2) {
          await stores[1].database.queue([
            SyncOperation('category.delete', category, expectedRevision: 1),
          ]);
          await _until(
            () async => !(await server(spaceId)).contains(category),
            'cleanup',
          );
        }
        for (final store in stores) {
          await store.close();
        }
        await directory.delete(recursive: true);
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
