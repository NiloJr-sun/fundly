import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/store_files.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spaces/data/active_space.dart';
import 'package:fundly/features/spaces/data/active_space_store.dart';
import 'package:fundly/features/spaces/data/device_space_stores.dart';
import 'package:fundly/features/spaces/data/space_removals.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';
import 'package:fundly/features/spaces/presentation/space_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_synced_store.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);
const household = '7c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5';
const trip = '11111111-2222-4333-8444-555555555555';
const _at = '2026-11-24 00:00:00+00';

/// What the server says the user belongs to.
class _Service implements SpaceService {
  Set<String> members = {userA.userId, household, trip};
  bool offline = false;
  int asked = 0;

  @override
  Future<Set<String>> memberSpaceIds() async {
    asked++;
    if (offline) throw Exception('offline');
    return members;
  }

  @override
  Future<Space> create({required String spaceId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<Space> rename(Space space, String name) => throw UnimplementedError();
}

/// Stores that are not open, by space id.
class _Files implements SpaceStoreFiles {
  final present = <String, StoreChanges>{};
  final deleted = <String>[];
  bool failDelete = false;

  @override
  Future<bool> exists(String userId, String spaceId) async =>
      present.containsKey(spaceId);

  @override
  Future<StoreChanges> changesIn(String userId, String spaceId) async =>
      present[spaceId]!;

  @override
  Future<void> delete(String userId, String spaceId) async {
    if (failDelete) throw Exception('another tab has it open');
    present.remove(spaceId);
    deleted.add(spaceId);
  }
}

/// A store whose spaces list holds Personal plus [listed] (name, role).
class _Store extends FakeSyncedStore {
  _Store(String spaceId, this.closedSpaces) : super(userA, spaceId: spaceId);

  final List<String> closedSpaces;

  @override
  Future<void> close() {
    if (!closed) closedSpaces.add(spaceId);
    return super.close();
  }

  Future<void> list(Map<String, (String, String)> spaces) => download({
    'spaces': [
      _space(userA.userId, 'Personal', personal: true),
      for (final MapEntry(:key, value: (name, _)) in spaces.entries)
        _space(key, name),
    ],
    'space_members': [
      _member(userA.userId, 'owner'),
      for (final MapEntry(:key, value: (_, role)) in spaces.entries)
        _member(key, role),
    ],
  });

  /// The membership leaves the download, as when the user is removed.
  Future<void> unlist(String spaceId) =>
      deleteDownloaded('space_members', '$spaceId:${userA.userId}');

  Future<void> refuseOne() => database.customStatement(
    'INSERT INTO sync_rejections (batch_id, kind, code, operations, '
    "created_ids, labels, rejected_at) VALUES ('b1', 'rejected', "
    "'not_space_member', '{\"version\":1,\"items\":[]}', '[]', '{}', "
    "'2026-11-24T00:00:00Z')",
  );

  static Map<String, Object?> _space(
    String id,
    String name, {
    bool personal = false,
  }) => {
    'id': id,
    'name': name,
    'personal_of': personal ? userA.userId : null,
    'created_by': userA.userId,
    'created_at': _at,
    'updated_at': _at,
    'revision': 1,
  };

  static Map<String, Object?> _member(String spaceId, String role) => {
    'id': '$spaceId:${userA.userId}',
    'space_id': spaceId,
    'user_id': userA.userId,
    'role': role,
    'created_at': _at,
    'updated_at': _at,
  };
}

void main() {
  late FakeAuthRepository auth;
  late InMemoryActiveSpaceStore remembered;
  late InMemoryDeviceSpaceStores deviceSpaces;
  late _Service service;
  late _Files files;
  late Map<String, _Store> stores;
  late List<String> closed;

  /// What each space's store downloads when it opens.
  late Map<String, (String, String)> listed;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        activeSpaceStoreProvider.overrideWithValue(remembered),
        deviceSpaceStoresProvider.overrideWithValue(deviceSpaces),
        spaceServiceProvider.overrideWithValue(service),
        spaceStoreFilesProvider.overrideWithValue(files),
        syncedStoreOpenerProvider.overrideWithValue((identity, spaceId) {
          final store = stores[spaceId] = _Store(spaceId, closed);
          store.list(listed);
          return store;
        }),
      ],
    );
    addTearDown(c.dispose);
    // As the app does: the store and the removal rules stay alive.
    c
      ..listen(syncedStoreProvider, (_, _) {})
      ..listen(spaceRemovalsProvider, (_, _) {})
      ..listen(canEditProvider, (_, _) {});
    return c;
  }

  setUp(() {
    auth = FakeAuthRepository(initial: userA);
    remembered = InMemoryActiveSpaceStore();
    deviceSpaces = InMemoryDeviceSpaceStores();
    service = _Service();
    files = _Files();
    stores = {};
    closed = [];
    listed = {household: ('Household', 'owner'), trip: ('Trip', 'editor')};
  });

  Future<void> settle() => pumpEventQueue(times: 50);

  test('every listed space but Personal goes on the device list, by name; '
      'nothing is asked while all are listed', () async {
    container();
    await settle();
    expect(deviceSpaces.spacesOf(userA.userId), {
      household: const DeviceSpace(spaceId: household, name: 'Household'),
      trip: const DeviceSpace(spaceId: trip, name: 'Trip'),
    });
    expect(service.asked, 0);
  });

  group('the active space leaves', () {
    setUp(() => remembered.remember(userA.userId, household));

    test('with nothing unsent or refused: deleted from the device, the app '
        'shows Personal and says which space', () async {
      final c = container();
      await settle();
      service.members = {userA.userId, trip};
      listed = {trip: ('Trip', 'editor')};
      await stores[household]!.unlist(household);
      await settle();

      expect(c.read(activeSpaceIdProvider), userA.userId);
      expect(closed, [household]);
      expect(files.deleted, [household]);
      expect(deviceSpaces.spacesOf(userA.userId).keys, [trip]);
      expect(c.read(spaceRemovalsProvider).notice, 'Household');
      expect(c.read(spaceRemovalsProvider).removed, isEmpty);
      c.read(spaceRemovalsProvider.notifier).dismissNotice();
      expect(c.read(spaceRemovalsProvider).notice, isNull);
    });

    test('with an unsent change: kept, active and read-only as Removed, '
        'until removed from the device', () async {
      final c = container();
      await settle();
      expect(c.read(canEditProvider), isTrue);
      stores[household]!.pendingUploads = 1;
      service.members = {userA.userId, trip};
      listed = {trip: ('Trip', 'editor')};
      await stores[household]!.unlist(household);
      await settle();

      expect(c.read(activeSpaceIdProvider), household);
      expect(closed, isEmpty);
      expect(files.deleted, isEmpty);
      expect(c.read(spaceRemovalsProvider).removed, const [
        DeviceSpace(spaceId: household, name: 'Household', removed: true),
      ]);
      expect(c.read(activeSpaceRemovedProvider), isTrue);
      expect(c.read(canEditProvider), isFalse);
      expect(c.read(spaceRemovalsProvider).notice, isNull);

      await c.read(spaceRemovalsProvider.notifier).removeFromDevice(household);
      await settle();
      expect(c.read(activeSpaceIdProvider), userA.userId);
      expect(closed, [household]);
      expect(files.deleted, [household]);
      expect(c.read(spaceRemovalsProvider).removed, isEmpty);
      expect(deviceSpaces.spacesOf(userA.userId).keys, [trip]);
    });

    test('with a refused change: kept as Removed too', () async {
      final c = container();
      await settle();
      await stores[household]!.refuseOne();
      service.members = {userA.userId, trip};
      listed = {trip: ('Trip', 'editor')};
      await stores[household]!.unlist(household);
      await settle();
      expect(c.read(activeSpaceIdProvider), household);
      expect(c.read(spaceRemovalsProvider).isRemoved(household), isTrue);
      expect(files.deleted, isEmpty);
    });

    test(
      'a list change alone decides nothing: the server must agree',
      () async {
        final c = container();
        await settle();
        await stores[household]!.unlist(household);
        await settle();
        expect(service.asked, 1);
        expect(c.read(activeSpaceIdProvider), household);
        expect(files.deleted, isEmpty);
        expect(c.read(spaceRemovalsProvider).removed, isEmpty);
      },
    );

    test('offline, nothing happens', () async {
      final c = container();
      await settle();
      service
        ..members = {userA.userId}
        ..offline = true;
      await stores[household]!.unlist(household);
      await settle();
      expect(c.read(activeSpaceIdProvider), household);
      expect(files.deleted, isEmpty);
      expect(c.read(spaceRemovalsProvider).removed, isEmpty);
    });
  });

  group('a space that is not open leaves', () {
    test('its store, with nothing unsent or refused, is deleted', () async {
      files.present[trip] = const StoreChanges(unsent: 0, refused: 0);
      final c = container();
      await settle();
      service.members = {userA.userId, household};
      await stores[userA.userId]!.unlist(trip);
      await settle();
      expect(files.deleted, [trip]);
      expect(deviceSpaces.spacesOf(userA.userId).keys, [household]);
      expect(c.read(spaceRemovalsProvider).removed, isEmpty);
      expect(c.read(spaceRemovalsProvider).notice, isNull);
      expect(c.read(activeSpaceIdProvider), userA.userId);
    });

    test('its store, with unsent changes, is kept as Removed; opening it '
        'is read-only', () async {
      files.present[trip] = const StoreChanges(unsent: 2, refused: 0);
      final c = container();
      await settle();
      service.members = {userA.userId, household};
      await stores[userA.userId]!.unlist(trip);
      await settle();
      expect(files.deleted, isEmpty);
      expect(c.read(spaceRemovalsProvider).removed.single.name, 'Trip');

      // Opening it to review: its own list no longer has it.
      listed = {household: ('Household', 'owner')};
      await c.read(activeSpaceIdProvider.notifier).select(trip);
      await settle();
      expect(c.read(syncedStoreProvider)!.spaceId, trip);
      expect(c.read(canEditProvider), isFalse);
      expect(files.deleted, isEmpty);
    });

    test('with no store on the device, it is just forgotten', () async {
      container();
      await settle();
      service.members = {userA.userId, household};
      await stores[userA.userId]!.unlist(trip);
      await settle();
      expect(files.deleted, isEmpty);
      expect(deviceSpaces.spacesOf(userA.userId).keys, [household]);
    });

    test(
      'a delete that fails keeps it listed, to try again next start',
      () async {
        files
          ..present[trip] = const StoreChanges(unsent: 0, refused: 0)
          ..failDelete = true;
        final c = container();
        await settle();
        service.members = {userA.userId, household};
        await stores[userA.userId]!.unlist(trip);
        await settle();
        expect(deviceSpaces.spacesOf(userA.userId).keys, contains(trip));
        expect(c.read(spaceRemovalsProvider).removed, isEmpty);
      },
    );
  });

  group('at start', () {
    test('a space that left while the app was closed is found from the '
        'device list', () async {
      await deviceSpaces.save(
        userA.userId,
        const DeviceSpace(spaceId: trip, name: 'Trip'),
      );
      files.present[trip] = const StoreChanges(unsent: 0, refused: 0);
      listed = {household: ('Household', 'owner')};
      service.members = {userA.userId, household};
      container();
      await settle();
      expect(files.deleted, [trip]);
      expect(deviceSpaces.spacesOf(userA.userId).keys, [household]);
    });

    test('a remembered space that left with nothing unsent: Personal, '
        'with the notice', () async {
      await remembered.remember(userA.userId, household);
      await deviceSpaces.save(
        userA.userId,
        const DeviceSpace(spaceId: household, name: 'Household'),
      );
      listed = {trip: ('Trip', 'editor')};
      service.members = {userA.userId, trip};
      final c = container();
      await settle();
      expect(c.read(activeSpaceIdProvider), userA.userId);
      expect(files.deleted, [household]);
      expect(c.read(spaceRemovalsProvider).notice, 'Household');
      expect(remembered.remembered(userA.userId), userA.userId);
    });

    test('an unlisted space the server still counts stays, and is not asked '
        'about again', () async {
      await deviceSpaces.save(
        userA.userId,
        const DeviceSpace(spaceId: trip, name: 'Trip'),
      );
      listed = {household: ('Household', 'owner')};
      container();
      await settle();
      expect(service.asked, 1);
      await stores[userA.userId]!.list(listed);
      await settle();
      expect(service.asked, 1);
      expect(deviceSpaces.spacesOf(userA.userId).keys, containsAll([trip]));
      expect(files.deleted, isEmpty);
    });

    test('a removed space listed again (invited back) is no longer '
        'Removed', () async {
      await deviceSpaces.save(
        userA.userId,
        const DeviceSpace(spaceId: trip, name: 'Trip', removed: true),
      );
      final c = container();
      expect(c.read(spaceRemovalsProvider).removed, hasLength(1));
      await settle();
      expect(c.read(spaceRemovalsProvider).removed, isEmpty);
      expect(
        deviceSpaces.spacesOf(userA.userId)[trip],
        const DeviceSpace(spaceId: trip, name: 'Trip'),
      );
    });
  });

  test('removing from the device only applies to Removed spaces', () async {
    files.present[trip] = const StoreChanges(unsent: 0, refused: 0);
    final c = container();
    await settle();
    await c.read(spaceRemovalsProvider.notifier).removeFromDevice(trip);
    expect(files.deleted, isEmpty);
  });

  group('edit gate', () {
    test('signed out and in Personal, always', () async {
      auth = FakeAuthRepository();
      expect(container().read(canEditProvider), isTrue);
      auth = FakeAuthRepository(initial: userA);
      final c = container();
      expect(c.read(canEditProvider), isTrue);
    });

    test('owners and editors may edit; viewers may not', () async {
      listed = {
        household: ('Household', 'owner'),
        trip: ('Trip', 'editor'),
        userB: ('Shared with me', 'viewer'),
      };
      service.members.add(userB);
      final c = container();
      await settle();
      for (final (space, canEdit) in [
        (household, true),
        (trip, true),
        (userB, false),
      ]) {
        await c.read(activeSpaceIdProvider.notifier).select(space);
        await settle();
        expect(c.read(canEditProvider), canEdit, reason: space);
      }
    });

    test('another space, before its list has downloaded: not yet', () async {
      await remembered.remember(userA.userId, household);
      listed = {};
      service.members = {userA.userId, household};
      final c = container();
      expect(c.read(canEditProvider), isFalse);
      await settle();
      expect(c.read(canEditProvider), isFalse);
      expect(files.deleted, isEmpty);
    });
  });

  group('device list in preferences', () {
    test('kept per user as JSON; a broken value reads as empty', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesDeviceSpaceStores.keyFor('broken'): 'not json',
      });
      final preferences = await SharedPreferences.getInstance();
      final saved = SharedPreferencesDeviceSpaceStores(preferences);
      await saved.save('u1', const DeviceSpace(spaceId: 's1', name: 'One'));
      await saved.save(
        'u1',
        const DeviceSpace(spaceId: 's2', name: 'Two', removed: true),
      );
      // A fresh reader of the same preferences (the next start).
      final again = SharedPreferencesDeviceSpaceStores(preferences);
      expect(again.spacesOf('u1'), {
        's1': const DeviceSpace(spaceId: 's1', name: 'One'),
        's2': const DeviceSpace(spaceId: 's2', name: 'Two', removed: true),
      });
      expect(again.spacesOf('u2'), isEmpty);
      expect(again.spacesOf('broken'), isEmpty);
      await again.forget('u1', 's1');
      expect(saved.spacesOf('u1').keys, ['s2']);
    });
  });
}

const userB = '00000000-0000-4000-8000-000000000001';
