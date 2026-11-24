import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import 'active_space_store.dart';

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
    // A remembered space the user no longer belongs to is handled by
    // spaceRemovalsProvider (shared spaces C3), which may keep it to review.
    return ref.read(activeSpaceStoreProvider).remembered(userId) ?? userId;
  }

  /// Shows [spaceId] from now on, on this device.
  Future<void> select(String spaceId) async {
    final identity = ref.read(authIdentityProvider);
    if (identity is! SignedIn || state == spaceId) return;
    state = spaceId;
    await ref.read(activeSpaceStoreProvider).remember(identity.userId, spaceId);
  }

  /// Back to Personal, for example when the chosen space left the user.
  Future<void> selectPersonal() async {
    final identity = ref.read(authIdentityProvider);
    if (identity is SignedIn) await select(identity.userId);
  }
}
