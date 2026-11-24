import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/batch_uploader.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spaces/data/active_space.dart';
import 'package:fundly/features/spaces/data/active_space_store.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_synced_store.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);
const userB = SignedIn(
  userId: '00000000-0000-4000-8000-000000000001',
  email: 'b@test.com',
);
const business = '7c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5';

class _Service implements SpaceService {
  _Service(this.ids);

  final Set<String> ids;

  @override
  Future<Set<String>> memberSpaceIds() async => ids;

  @override
  Future<Space> create({required String spaceId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<Space> rename(Space space, String name) => throw UnimplementedError();
}

void main() {
  late FakeAuthRepository auth;
  late InMemoryActiveSpaceStore remembered;
  late List<(String, String)> opened;
  late List<String> closed;

  ProviderContainer container({SpaceService? service}) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        activeSpaceStoreProvider.overrideWithValue(remembered),
        spaceServiceProvider.overrideWithValue(service),
        syncedStoreOpenerProvider.overrideWithValue((identity, spaceId) {
          opened.add((identity.userId, spaceId));
          return _RecordingStore(identity, spaceId, closed);
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    auth = FakeAuthRepository(initial: userA);
    remembered = InMemoryActiveSpaceStore();
    opened = [];
    closed = [];
  });

  test('signed out there is no active space and no store', () {
    auth = FakeAuthRepository();
    final c = container();
    expect(c.read(activeSpaceIdProvider), isNull);
    expect(c.read(syncedStoreProvider), isNull);
  });

  test('signed in, Personal (the user id) is active by default', () {
    final c = container();
    expect(c.read(activeSpaceIdProvider), userA.userId);
    expect(c.read(syncedStoreProvider)!.spaceId, userA.userId);
    expect(opened, [(userA.userId, userA.userId)]);
  });

  test('a remembered space opens first, without opening Personal', () async {
    await remembered.remember(userA.userId, business);
    final c = container(service: _Service({userA.userId, business}));
    expect(c.read(syncedStoreProvider)!.spaceId, business);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(activeSpaceIdProvider), business);
    expect(opened, [(userA.userId, business)]);
  });

  test('choosing a space closes the old store, opens the new one and is '
      'remembered', () async {
    final c = container();
    final personal = c.read(syncedStoreProvider)!;
    await c.read(activeSpaceIdProvider.notifier).select(business);
    expect(c.read(syncedStoreProvider)!.spaceId, business);
    expect(closed, [personal.spaceId]);
    expect(remembered.remembered(userA.userId), business);
  });

  test('each user has their own remembered space', () async {
    await remembered.remember(userA.userId, business);
    final c = container(service: _Service({userA.userId, business}));
    c.read(syncedStoreProvider);
    auth.emit(userB);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(activeSpaceIdProvider), userB.userId);
    expect(c.read(syncedStoreProvider)!.spaceId, userB.userId);
  });

  group('upload envelope', () {
    const operations = <String, dynamic>{'version': 1, 'items': <Object>[]};

    test('Personal batches are sent exactly as queued', () {
      final sent = envelopeForSpace(
        operations,
        userId: userA.userId,
        spaceId: userA.userId,
      );
      expect(sent, operations);
      expect(sent.containsKey('space_id'), isFalse);
    });

    test('another space\'s batches name it', () {
      final sent = envelopeForSpace(
        operations,
        userId: userA.userId,
        spaceId: business,
      );
      expect(sent, {...operations, 'space_id': business});
      expect(operations.containsKey('space_id'), isFalse);
    });
  });
}

class _RecordingStore extends FakeSyncedStore {
  _RecordingStore(super.identity, String spaceId, this._closed)
    : super(spaceId: spaceId);

  final List<String> _closed;

  @override
  Future<void> close() async {
    _closed.add(spaceId);
    await super.close();
  }
}
