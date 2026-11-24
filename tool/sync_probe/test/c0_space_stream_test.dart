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
import 'package:fundly_sync_probe/c0/c0_spaces.dart';
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

Future<Duration> _until(Future<bool> Function() condition, String label) =>
    waitUntil(condition, label);

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

  late C0Config config;
  late C0User a, b, c;
  final spaces = <String>[];
  final stores = <C0Store>[];
  final directories = <Directory>[];

  Future<String> newSpace(String name) async {
    final space = const Uuid().v4();
    await a.createSpace(space, name);
    spaces.add(space);
    return space;
  }

  Future<C0Store> open(
    C0User user,
    String space, {
    bool logRefusals = true,
    bool member = true,
  }) async {
    final directory = await Directory.systemTemp.createTemp('fundly-c0-');
    directories.add(directory);
    final store = await C0Store.open(
      '${directory.path}/${c0StoreName(user, space)}.sqlite',
      config,
      user,
      space,
      logRefusals: logRefusals,
    );
    stores.add(store);
    await store.sync(member: member);
    return store;
  }

  setUpAll(() async {
    if (skip != null) return;
    final values = jsonDecode(
      File(_environment['C0_CHECK_CONFIG'] ?? 'cloud/c0/config.local.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    config = C0Config(
      supabaseUrl: values['SUPABASE_URL']! as String,
      publishableKey: values['SUPABASE_PUBLISHABLE_KEY']! as String,
      powerSyncUrl: values['POWERSYNC_URL']! as String,
    );
    Future<C0User> signIn(String letter) => C0User.signIn(
      config,
      letter,
      _environment['C0_TEST_${letter}_EMAIL']!,
      _environment['C0_TEST_${letter}_PASSWORD']!,
    );

    a = await signIn('A');
    b = await signIn('B');
    c = await signIn('C');
    expect({a.id, b.id, c.id}, hasLength(3));
  });

  tearDown(() async {
    for (final store in stores) {
      await store.close(clear: true);
    }
    stores.clear();
    for (final directory in directories) {
      await directory.delete(recursive: true);
    }
    directories.clear();
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
