import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import 'active_space_store.dart';
import 'space_service.dart';

/// The space the app shows for the signed-in user (shared spaces C2), or
/// null while signed out. Personal (whose id is the user's) unless the user
/// chose another space on this device.
final activeSpaceIdProvider = NotifierProvider<ActiveSpace, String?>(
  ActiveSpace.new,
);

class ActiveSpace extends Notifier<String?> {
  @override
  String? build() {
    final userId = ref.watch(
      authIdentityProvider.select(
        (identity) => identity is SignedIn ? identity.userId : null,
      ),
    );
    if (userId == null) return null;
    final remembered = ref.read(activeSpaceStoreProvider).remembered(userId);
    if (remembered != null && remembered != userId) {
      Future.microtask(() => _confirmMembership(userId, remembered));
    }
    return remembered ?? userId;
  }

  /// Falls back to Personal when the server says the remembered space is not
  /// one of the user's (any more). Offline, the remembered space stays.
  Future<void> _confirmMembership(String userId, String spaceId) async {
    final service = ref.read(spaceServiceProvider);
    if (service == null) return;
    try {
      final ids = await service.memberSpaceIds();
      if (!ids.contains(spaceId) && state == spaceId) await selectPersonal();
    } on Object {
      // Offline or the server is busy: keep the space; checked next start.
    }
  }

  /// Shows [spaceId] from now on, on this device.
  Future<void> select(String spaceId) async {
    final identity = ref.read(authIdentityProvider);
    if (identity is! SignedIn || state == spaceId) return;
    state = spaceId;
    await ref.read(activeSpaceStoreProvider).remember(identity.userId, spaceId);
  }

  /// Back to Personal, for example when the chosen space is not (or no
  /// longer) one the user belongs to.
  Future<void> selectPersonal() async {
    final identity = ref.read(authIdentityProvider);
    if (identity is SignedIn) await select(identity.userId);
  }
}
