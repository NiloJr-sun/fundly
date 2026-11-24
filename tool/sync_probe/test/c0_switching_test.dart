// Shared spaces C0.3: switching between space stores on one device
// (docs/SHARED_SPACES_C0_PLAN.md), against the LOCAL C0 environment. Runs on
// the VM, in Chrome and (through integration_test/c0_switching_test.dart) on
// the iOS simulator. Endpoints and test users come from --dart-define files,
// so nothing depends on dart:io; skipped without them. From tool/sync_probe:
//
//   cloud/c0/defines.sh > <scratch>/c0_users.json   # chmod 600, git-ignored
//   flutter test test/c0_switching_test.dart \
//     --dart-define-from-file=cloud/c0/config.local.json \
//     --dart-define-from-file=<scratch>/c0_users.json
//   (Chrome: add --platform chrome
//     --dart-define=PROBE_ASSET_PREFIX=/packages/fundly_sync_probe/web_assets/)
//
// Credentials and tokens are never printed. Spaces are deleted afterwards.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly_sync_probe/c0/c0_spaces.dart';
import 'package:uuid/uuid.dart';

import 'scratch_native.dart' if (dart.library.js_interop) 'scratch_web.dart';

const _users = {
  'A': (
    String.fromEnvironment('C0_TEST_A_EMAIL'),
    String.fromEnvironment('C0_TEST_A_PASSWORD'),
  ),
  'B': (
    String.fromEnvironment('C0_TEST_B_EMAIL'),
    String.fromEnvironment('C0_TEST_B_PASSWORD'),
  ),
};

void main() {
  final config = C0Config.fromEnvironment();
  final ready =
      config.isComplete &&
      _users.values.every((user) => user.$1.isNotEmpty && user.$2.isNotEmpty);
  final skip = ready
      ? null
      : 'Live C0 check: pass config.local.json and the test users as '
            '--dart-define-from-file';

  late C0User a, b;
  final spaces = <String>[];
  final open = <C0Store>[];
  final paths = <String>[];

  Future<String> newSpace(String name, String entry) async {
    final space = const Uuid().v4();
    await a.createSpace(space, name);
    spaces.add(space);
    await a.put(space, entry, '$name entry');
    return space;
  }

  Future<C0Store> openStore(String path, C0User user, String space) async {
    final store = await C0Store.open(path, config, user, space);
    open.add(store);
    return store;
  }

  Future<String> newPath() async {
    final path = await scratchPath();
    paths.add(path);
    return path;
  }

  setUpAll(() async {
    if (skip != null) return;
    Future<C0User> signIn(String name, C0Config config) =>
        C0User.signIn(config, name, _users[name]!.$1, _users[name]!.$2);
    a = await signIn('A', config);
    // Its own host name, so a browser keeps A's and B's sessions apart.
    b = await signIn('B', config.withLocalhost());
    expect(a.id, isNot(b.id));
  });

  tearDown(() async {
    for (final store in open) {
      await store.close(clear: true);
    }
    open.clear();
    for (final path in paths) {
      await removeScratch(path);
    }
    paths.clear();
    for (final space in spaces) {
      await a.deleteSpace(space);
    }
    spaces.clear();
  });

  const timeout = Timeout(Duration(minutes: 3));

  test(
    'switching between two space stores keeps each one\'s data, '
    'without downloading it again',
    () async {
      final e1 = const Uuid().v4(), e2 = const Uuid().v4();
      final s1 = await newSpace('C0 switch one', e1);
      final s2 = await newSpace('C0 switch two', e2);
      final path1 = await newPath(), path2 = await newPath();

      // Open S1, sync, switch away (close without clearing).
      var store1 = await openStore(path1, a, s1);
      await store1.sync();
      expect(await store1.ids('c0_entries'), {e1});
      await store1.close();
      open.remove(store1);

      // Open S2, sync, switch away.
      var store2 = await openStore(path2, a, s2);
      await store2.sync();
      expect(await store2.ids('c0_entries'), {e2});
      await store2.close();
      open.remove(store2);

      // Switch back to S1: its data is there before connecting.
      store1 = await openStore(path1, a, s1);
      expect(await store1.ids('c0_entries'), {e1}, reason: 'kept offline');
      expect(await store1.ids('c0_spaces'), {s1, s2});
      final e3 = const Uuid().v4();
      await a.put(s1, e3, 'Added while switched away');
      await store1.sync();
      await waitUntil(
        () async => (await store1.ids('c0_entries')).contains(e3),
        'change made while switched away arrives',
      );
      expect(await store1.ids('c0_entries'), {e1, e3});

      // And S2 is still intact on the device, untouched by S1's sync.
      store2 = await openStore(path2, a, s2);
      expect(await store2.ids('c0_entries'), {e2}, reason: 'kept offline');
    },
    skip: skip,
    timeout: timeout,
  );

  test(
    'two spaces open at once, for two users, stay apart',
    () async {
      final e1 = const Uuid().v4(), e2 = const Uuid().v4();
      final s1 = await newSpace('C0 together one', e1);
      final s2 = await newSpace('C0 together two', e2);
      await a.setMember(s2, b, 'editor');

      final aS1 = await openStore(await newPath(), a, s1);
      final aS2 = await openStore(await newPath(), a, s2);
      final bS2 = await openStore(await newPath(), b, s2);
      final bS1 = await openStore(await newPath(), b, s1);
      await Future.wait([
        aS1.sync(),
        aS2.sync(),
        bS2.sync(),
        bS1.sync(member: false),
      ]);

      expect(await aS1.ids('c0_entries'), {e1});
      expect(await aS2.ids('c0_entries'), {e2});
      expect(await bS2.ids('c0_entries'), {e2});
      expect(await bS1.ids('c0_entries'), isEmpty, reason: 'B is not in S1');
      expect(await bS2.ids('c0_spaces'), {s2});

      // A write in one open store reaches the other user's store of that
      // space, and nowhere else.
      final fromB = const Uuid().v4();
      await bS2.database.execute(
        'INSERT INTO c0_entries (id, space_id, label, amount_minor, revision) '
        'VALUES (?, ?, ?, ?, 1)',
        [fromB, s2, 'From B', 250],
      );
      await waitUntil(
        () async => (await aS2.ids('c0_entries')).contains(fromB),
        'B\'s write reaches A\'s store of the same space',
      );
      expect(await aS1.ids('c0_entries'), {e1});
      expect(await bS1.ids('c0_entries'), isEmpty);
    },
    skip: skip,
    timeout: timeout,
  );
}
