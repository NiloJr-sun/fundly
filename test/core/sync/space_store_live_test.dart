// Shared spaces C2.2: the real PowerSyncStore with two spaces, against the
// LOCAL stack and self-hosted PowerSync (tool/sync_probe/cloud/fundly-local).
// C3.2 adds sharing with user B: invites and members through the app's
// service, and B's store after B is removed with a change not yet sent.
// Skipped unless FUNDLY_TEST_A_EMAIL/PASSWORD (and _B_ for C3.2) and
// FUNDLY_CHECK_CONFIG are set:
//
//   tool/sync_probe/cloud/fundly-local/up.sh
//   set -a; . tool/sync_probe/cloud/fundly-local/.env.local; set +a
//   FUNDLY_CHECK_CONFIG=tool/sync_probe/cloud/fundly-local/config.local.json \
//     flutter test test/core/sync/space_store_live_test.dart
//
// Refuses anything but a local stack. The C2.2 space is fixed per test user;
// records written here are deleted. The C3.2 space is created and deleted.
// Credentials and invite secrets are never printed.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/powersync_store.dart';
import 'package:fundly/core/sync/store_files.dart';
import 'package:fundly/core/sync/sync_queue.dart';
import 'package:fundly/core/sync/sync_rejections.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spaces/data/sharing_service.dart';
import 'package:fundly/features/spaces/data/space_directory.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';
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
    'first sign-in creates Personal without any prior server write',
    () async {
      final config = jsonDecode(
        File(configPath).readAsStringSync(),
      ) as Map<String, Object?>;
      final url = config['SUPABASE_URL']! as String;
      if (!url.startsWith('http://127.0.0.1:')) {
        fail('This check creates a user: local stack only');
      }
      final client = SupabaseClient(
        url,
        config['SUPABASE_PUBLISHABLE_KEY']! as String,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final email = 'fundly-first-${const Uuid().v4()}@example.test';
      final password = const Uuid().v4();
      final signedUp = await client.auth.signUp(
        email: email,
        password: password,
      );
      final userId = signedUp.user!.id;
      final directory = await Directory.systemTemp.createTemp('fundly-first-');
      SyncedStore? store;
      try {
        if (signedUp.session == null) {
          await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
        }
        expect(await client.from('spaces').select('id'), isEmpty);
        final personal = store = PowerSyncStore.open(
          SignedIn(userId: userId, email: email),
          userId,
          client: client,
          powerSyncUrl: config['POWERSYNC_URL']! as String,
          directory: () async => directory.path,
        );
        await personal
            .watchState()
            .firstWhere((state) => state.hasSynced)
            .timeout(const Duration(seconds: 60));
        await _until(() async {
          final categories = await personal.database
              .customSelect('SELECT id FROM categories')
              .get();
          return categories.length == 9 &&
              await personal.watchPendingUploads().first == 0;
        }, 'Personal defaults download');
        expect(await client.from('spaces').select('id'), [
          {'id': userId},
        ]);
      } finally {
        await store?.close();
        await directory.delete(recursive: true);
        await client.dispose();
        // The new local user owns only the default categories and write receipt.
        final cleanup = await Process.run('docker', [
          'exec',
          'supabase_db_fundly-schema-dev',
          'psql',
          '-U',
          'postgres',
          '-v',
          'ON_ERROR_STOP=1',
          '-c',
          "BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id='$userId'; "
              "DELETE FROM public.categories WHERE owner_id='$userId'; "
              "DELETE FROM public.fundly_deleted_records WHERE owner_id='$userId'; "
              "DELETE FROM auth.users WHERE id='$userId'; COMMIT;",
        ]);
        expect(cleanup.exitCode, 0, reason: '${cleanup.stderr}');
      }
    },
    skip: configPath.isEmpty ? 'Live check: set FUNDLY_CHECK_CONFIG' : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

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

  final sharingSkip =
      skip ??
      ((_environment['FUNDLY_TEST_B_EMAIL'] ?? '').isEmpty ||
              (_environment['FUNDLY_TEST_B_PASSWORD'] ?? '').isEmpty
          ? 'Live check: set FUNDLY_TEST_B_*'
          : null);

  test(
    'sharing: invite and accept, members reach the store, and removal with '
    'an unsent change keeps it refused on the device',
    () async {
      final config = jsonDecode(
        File(configPath).readAsStringSync(),
      ) as Map<String, Object?>;
      final url = config['SUPABASE_URL']! as String;
      if (!url.startsWith('http://127.0.0.1:')) {
        fail('This check writes to the server: local stack only');
      }
      final key = config['SUPABASE_PUBLISHABLE_KEY']! as String;
      final powerSyncUrl = config['POWERSYNC_URL']! as String;
      Future<(SupabaseClient, SignedIn)> signIn(String who) async {
        final client = SupabaseClient(url, key);
        final session = await client.auth.signInWithPassword(
          email: _environment['FUNDLY_TEST_${who}_EMAIL']!,
          password: _environment['FUNDLY_TEST_${who}_PASSWORD']!,
        );
        return (
          client,
          SignedIn(userId: session.user!.id, email: session.user!.email ?? ''),
        );
      }

      final (clientA, a) = await signIn('A');
      final (clientB, b) = await signIn('B');
      final sharingA = SupabaseSharingService(clientA);
      final sharingB = SupabaseSharingService(clientB);
      final spaceId = const Uuid().v4();
      await SupabaseSpaceService(clientA)
          .create(spaceId: spaceId, name: 'C3.2 ${spaceId.substring(0, 8)}');
      final directory = await Directory.systemTemp.createTemp('fundly-c32-');
      final files = PowerSyncStoreFiles(directory: () async => directory.path);
      PowerSyncStore openB({bool connect = true}) => PowerSyncStore.open(
        b,
        spaceId,
        client: clientB,
        powerSyncUrl: connect ? powerSyncUrl : '',
        directory: () async => directory.path,
      );
      PowerSyncStore? store;
      try {
        // Invites, through the app's service: the secret only once.
        final invite = await sharingA.createInvite(
          spaceId: spaceId,
          email: b.email.toUpperCase(),
          role: SpaceRole.editor,
        );
        expect(invite.email, b.email.toLowerCase());
        expect(invite.secret, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(invite.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
        final pending = await sharingA.listInvites(spaceId);
        expect(pending.map((i) => i.id), [invite.id]);
        expect(pending.single.role, SpaceRole.editor);
        // A second invite, revoked; B cannot read someone else's invite.
        final extra = await sharingA.createInvite(
          spaceId: spaceId,
          email: 'c32-nobody@example.com',
          role: SpaceRole.viewer,
        );
        await sharingA.revokeInvite(extra.id);
        expect((await sharingA.listInvites(spaceId)).map((i) => i.id), [
          invite.id,
        ]);
        await expectLater(
          sharingB.previewInvite(extra.secret),
          throwsA(
            isA<SharingException>().having(
              (e) => e.problem,
              'problem',
              // Another email's invite reveals nothing, revoked or not.
              SharingProblem.inviteOtherEmail,
            ),
          ),
        );

        final preview = await sharingB.previewInvite(invite.secret);
        expect(preview.spaceId, spaceId);
        expect(preview.role, SpaceRole.editor);
        expect(preview.inviterEmail, a.email.toLowerCase());
        expect(preview.alreadyMember, isFalse);
        final joined = await sharingB.acceptInvite(invite.secret);
        expect((joined.spaceId, joined.role), (spaceId, SpaceRole.editor));
        await expectLater(
          sharingB.acceptInvite(invite.secret),
          throwsA(isA<SharingException>()),
        );

        // B's store gets the space and A's email; a role change arrives.
        store = openB();
        await store
            .watchState()
            .firstWhere((state) => state.hasSynced)
            .timeout(const Duration(seconds: 60));
        // A new space gets its default categories from the first store that
        // downloads it (here B's): let that upload finish first.
        final first = store;
        await _until(
          () async =>
              (await clientA
                      .from('categories')
                      .select('id')
                      .eq('space_id', spaceId))
                  .isNotEmpty &&
              (await first.watchPendingUploads().first) == 0,
          "B's first uploads finish",
        );
        expect([
          for (final r in await first.database.watchRejections().first) r.code,
        ], isEmpty);
        final members = await watchMembers(
          store.database,
          spaceId,
        ).firstWhere((members) => members.length == 2);
        expect(
          members.map((m) => m.email),
          containsAll([a.email.toLowerCase(), b.email.toLowerCase()]),
        );
        await sharingA.setMemberRole(
          spaceId: spaceId,
          userId: b.userId,
          role: SpaceRole.viewer,
        );
        await watchSpaces(store.database, b.userId)
            .firstWhere(
              (spaces) => spaces.any(
                (s) => s.id == spaceId && s.role == SpaceRole.viewer,
              ),
            )
            .timeout(const Duration(seconds: 60));
        await sharingA.setMemberRole(
          spaceId: spaceId,
          userId: b.userId,
          role: SpaceRole.editor,
        );
        await watchSpaces(store.database, b.userId)
            .firstWhere(
              (spaces) => spaces.any(
                (s) => s.id == spaceId && s.role == SpaceRole.editor,
              ),
            )
            .timeout(const Duration(seconds: 60));
        await store.close();

        // B makes a change that cannot upload yet (the store is offline),
        // then A removes B.
        store = openB(connect: false);
        await store.database.queue([
          SyncOperation(
            'category.create',
            newRecordId(),
            data: const {'name': 'C3.2 never sent', 'kind': 'spending'},
          ),
        ]);
        expect(await store.watchPendingUploads().first, 1);
        await store.close();
        await sharingA.removeMember(spaceId: spaceId, userId: b.userId);

        // Closed, the store still holds it: the device keeps the space.
        expect(await files.exists(b.userId, spaceId), isTrue);
        final waiting = await files.changesIn(b.userId, spaceId);
        expect((waiting.unsent, waiting.refused), (1, 0));

        // Opened to review it: the server refuses it as no longer a member,
        // it lands in Refused changes, and the space's rows leave.
        final reviewed = store = openB();
        final refused = await reviewed.database
            .watchRejections()
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 60));
        expect(refused.single.code, 'not_space_member');
        await _until(
          () async =>
              (await reviewed.watchPendingUploads().first) == 0 &&
              (await reviewed.database
                      .customSelect('SELECT id FROM categories')
                      .get())
                  .isEmpty &&
              !(await watchSpaces(
                reviewed.database,
                b.userId,
              ).first).any((s) => s.id == spaceId),
          'the space leaves the store, its refused change stays',
        );
        await expectLater(
          sharingB.leaveSpace(spaceId),
          throwsA(
            isA<SharingException>().having(
              (e) => e.problem,
              'problem',
              SharingProblem.notMember,
            ),
          ),
        );
        await reviewed.close();
        final kept = await files.changesIn(b.userId, spaceId);
        expect([for (final r in refused) r.code], ['not_space_member']);
        expect((kept.unsent, kept.refused), (0, 1));

        // Removed from the device once reviewed.
        await files.delete(b.userId, spaceId);
        expect(await files.exists(b.userId, spaceId), isFalse);
        expect(directory.listSync(), isEmpty);
      } finally {
        await store?.close();
        await sharingA.deleteSpace(
          spaceId: spaceId,
          name: ' c3.2 ${spaceId.substring(0, 8)} ',
        );
        await directory.delete(recursive: true);
      }
    },
    skip: sharingSkip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
