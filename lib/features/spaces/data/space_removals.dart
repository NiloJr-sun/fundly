import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/store_files.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../domain/space.dart';
import 'active_space.dart';
import 'device_space_stores.dart';
import 'space_directory.dart';
import 'space_service.dart';

/// Spaces leaving this device, for the space sheet and the screens.
@immutable
final class SpaceRemovalState {
  const SpaceRemovalState({this.removed = const [], this.notice});

  /// Spaces that left the user but are kept read-only on this device until
  /// the user reviews their unsent or refused changes (Decision C3-6).
  final List<DeviceSpace> removed;

  /// The name of the active space that left and was deleted from this
  /// device, after which the app showed Personal; until dismissed. Empty
  /// when the name was never known here.
  final String? notice;

  bool isRemoved(String spaceId) =>
      removed.any((space) => space.spaceId == spaceId);

  @override
  bool operator ==(Object other) =>
      other is SpaceRemovalState &&
      listEquals(other.removed, removed) &&
      other.notice == notice;

  @override
  int get hashCode => Object.hash(Object.hashAll(removed), notice);
}

/// Opens nothing but files: set in `main.dart`; `null` in tests unless
/// overridden, and in builds without the cloud configuration (no stores).
final spaceStoreFilesProvider = Provider<SpaceStoreFiles?>((ref) => null);

/// What happens when a space leaves a device (removed, left or deleted;
/// shared spaces C3, Decision C3-6).
///
/// The device lists every space it has seen ([DeviceSpaceStores]). When one
/// is no longer in the downloaded spaces list, or at start when the list may
/// be stale, the server is asked which spaces the user belongs to; only its
/// answer counts. For a space that left:
///
/// - its store holds no unsent or refused changes: the store is deleted
///   from the device; if it was active, the app shows Personal and
///   [SpaceRemovalState.notice] names the space;
/// - otherwise it stays, read-only and listed in
///   [SpaceRemovalState.removed], until [removeFromDevice].
///
/// The active store keeps syncing until then: the server refuses its
/// uploads (`not_space_member`), which land in Refused changes as usual.
/// Offline, nothing is decided; the next list change or start tries again,
/// as does a delete that failed (on the web, another tab may hold the
/// store).
final spaceRemovalsProvider =
    NotifierProvider<SpaceRemovals, SpaceRemovalState>(SpaceRemovals.new);

class SpaceRemovals extends Notifier<SpaceRemovalState> {
  /// Spaces the server confirmed this session, until they leave the list.
  final _confirmed = <String>{};
  final _asking = <String>{};
  Set<String> _listed = const {};
  String? _userId;

  @override
  SpaceRemovalState build() {
    final userId = _userId = ref.watch(
      authIdentityProvider.select(
        (identity) => identity is SignedIn ? identity.userId : null,
      ),
    );
    _confirmed.clear();
    _asking.clear();
    _listed = const {};
    if (userId == null) return const SpaceRemovalState();
    ref.listen(spacesProvider, (_, next) {
      if (next.value case final spaces?) {
        Future.microtask(() => _onListed(userId, spaces));
      }
    }, fireImmediately: true);
    return SpaceRemovalState(removed: _removedOf(userId));
  }

  DeviceSpaceStores get _stores => ref.read(deviceSpaceStoresProvider);

  List<DeviceSpace> _removedOf(String userId) => [
    for (final space in _stores.spacesOf(userId).values)
      if (space.removed) space,
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  void _refresh(String userId, {String? notice}) {
    if (_userId != userId) return;
    state = SpaceRemovalState(
      removed: _removedOf(userId),
      notice: notice ?? state.notice,
    );
  }

  Future<void> _onListed(String userId, List<Space> spaces) async {
    if (_userId != userId) return;
    final known = _stores.spacesOf(userId);
    final listed = <String>{};
    for (final space in spaces) {
      if (space.isPersonal) continue;
      listed.add(space.id);
      // Listed again (invited back) clears Removed.
      final entry = DeviceSpace(spaceId: space.id, name: space.name);
      if (known[space.id] != entry) await _stores.save(userId, entry);
    }
    _confirmed.removeAll(_listed.difference(listed));
    _listed = listed;
    _refresh(userId);

    final active = ref.read(activeSpaceIdProvider);
    final unlisted = {
      for (final space in _stores.spacesOf(userId).values)
        if (!space.removed) space.spaceId,
      if (active != null && active != userId && !state.isRemoved(active))
        active,
    }.difference(listed).difference(_confirmed).difference(_asking);
    if (unlisted.isNotEmpty) await _ask(userId, unlisted);
  }

  Future<void> _ask(String userId, Set<String> spaceIds) async {
    final service = ref.read(spaceServiceProvider);
    if (service == null) return;
    _asking.addAll(spaceIds);
    Set<String> members;
    try {
      members = await service.memberSpaceIds();
    } on Object {
      return; // Offline or busy: decided on the next change or start.
    } finally {
      _asking.removeAll(spaceIds);
    }
    for (final spaceId in spaceIds) {
      if (_userId != userId) return;
      if (members.contains(spaceId)) {
        _confirmed.add(spaceId);
      } else {
        await _spaceLeft(userId, spaceId);
      }
    }
  }

  Future<void> _spaceLeft(String userId, String spaceId) async {
    final entry =
        _stores.spacesOf(userId)[spaceId] ??
        DeviceSpace(spaceId: spaceId, name: '');
    try {
      final store = ref.read(syncedStoreProvider);
      if (store != null && store.spaceId == spaceId) {
        if (!(await _changesInOpen(store)).isEmpty) {
          await _keep(userId, entry);
          return;
        }
        await ref.read(activeSpaceIdProvider.notifier).selectPersonal();
        await store.close();
        await _delete(userId, spaceId, notice: entry.name);
        return;
      }
      final files = ref.read(spaceStoreFilesProvider);
      if (files == null) return;
      if (!await files.exists(userId, spaceId)) {
        await _stores.forget(userId, spaceId);
        _refresh(userId);
      } else if ((await files.changesIn(userId, spaceId)).isEmpty) {
        await _delete(userId, spaceId);
      } else {
        await _keep(userId, entry);
      }
    } on Object catch (error) {
      // Kept as it is; tried again on the next start.
      debugPrint('Could not clear a space that left this device: $error');
    }
  }

  Future<StoreChanges> _changesInOpen(SyncedStore store) async => StoreChanges(
    unsent: await store.watchPendingUploads().first,
    refused: (await store.database.select(store.database.syncRejections).get())
        .length,
  );

  Future<void> _keep(String userId, DeviceSpace entry) async {
    await _stores.save(userId, entry.copyWith(removed: true));
    _refresh(userId);
  }

  Future<void> _delete(String userId, String spaceId, {String? notice}) async {
    await ref.read(spaceStoreFilesProvider)?.delete(userId, spaceId);
    await _stores.forget(userId, spaceId);
    _refresh(userId, notice: notice);
  }

  /// Deletes a removed space's store from this device once the user has
  /// reviewed it ("Remove from this device"); shows Personal first if it was
  /// active. Throws when the store could not be deleted (it stays listed).
  Future<void> removeFromDevice(String spaceId) async {
    final userId = _userId;
    if (userId == null || !state.isRemoved(spaceId)) return;
    final store = ref.read(syncedStoreProvider);
    if (store != null && store.spaceId == spaceId) {
      await ref.read(activeSpaceIdProvider.notifier).selectPersonal();
      await store.close();
    }
    await _delete(userId, spaceId);
  }

  /// Clears [SpaceRemovalState.notice] once shown.
  void dismissNotice() {
    if (state.notice != null) {
      state = SpaceRemovalState(removed: state.removed);
    }
  }
}
