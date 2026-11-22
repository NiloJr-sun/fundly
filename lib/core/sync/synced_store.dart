import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_identity.dart';
import 'synced_database.dart';

/// How the synchronized store's connection is doing, for the status line.
enum SyncConnection {
  /// The build has no PowerSync configuration; the store opens but never
  /// downloads.
  notConfigured,
  connecting,
  connected,

  /// Not connected and not trying right now (for example, no network).
  offline,

  /// Connecting or downloading failed; PowerSync keeps retrying.
  failed,
}

/// A snapshot of the synchronized store for the status line.
class SyncState {
  const SyncState({
    required this.connection,
    this.hasSynced = false,
    this.lastSyncedAt,
    this.error,
  });

  final SyncConnection connection;

  /// Whether a complete download has ever finished on this device.
  final bool hasSynced;
  final DateTime? lastSyncedAt;

  /// The last connection or download error, for the "failed" state.
  final String? error;

  @override
  bool operator ==(Object other) =>
      other is SyncState &&
      other.connection == connection &&
      other.hasSynced == hasSynced &&
      other.lastSyncedAt == lastSyncedAt &&
      other.error == error;

  @override
  int get hashCode => Object.hash(connection, hasSynced, lastSyncedAt, error);
}

/// A signed-in user's synchronized records and their sync connection.
abstract interface class SyncedStore {
  SyncedDatabase get database;

  /// The connection state; emits the current state first.
  Stream<SyncState> watchState();

  /// Disconnects and closes the store.
  Future<void> close();
}

/// Opens the synchronized store for a signed-in user. Set in `main.dart` when
/// the build carries the cloud configuration; tests override it with an
/// in-memory store. `null` means signed-in use has no store (only possible in
/// tests), so the providers below fail clearly instead of guessing.
final syncedStoreOpenerProvider = Provider<SyncedStore Function(SignedIn)?>(
  (ref) => null,
);

/// The open synchronized store while signed in, or `null` while signed out.
///
/// Opening and closing follow the identity: a different user closes the old
/// store (disconnecting it) before the new one is used. A token refresh for
/// the same user keeps the same store.
final syncedStoreProvider = Provider<SyncedStore?>((ref) {
  final userId = ref.watch(
    authIdentityProvider.select(
      (identity) => identity is SignedIn ? identity.userId : null,
    ),
  );
  if (userId == null) return null;
  final open = ref.watch(syncedStoreOpenerProvider);
  if (open == null) {
    throw StateError('No synchronized store is available in this build.');
  }
  final identity = ref.read(authIdentityProvider) as SignedIn;
  final store = open(identity);
  ref.onDispose(store.close);
  return store;
});

/// The sync status for the Profile tab, or `null` while signed out.
final syncStateProvider = StreamProvider<SyncState?>((ref) {
  final store = ref.watch(syncedStoreProvider);
  if (store == null) return Stream.value(null);
  return store.watchState();
});

/// How many downloaded rows are hidden because their numbers are too large
/// for the web app to show exactly (normally 0).
final unsafeSyncedRowCountProvider = StreamProvider<int>((ref) {
  final store = ref.watch(syncedStoreProvider);
  if (store == null) return Stream.value(0);
  return store.database.watchUnsafeNumberCount();
});

/// Whether records can be changed. Signed in, the app only receives data
/// until sync uploads arrive (S5.3).
final canEditProvider = Provider<bool>(
  (ref) => ref.watch(authIdentityProvider) is! SignedIn,
);

/// Thrown by a synchronized repository's write methods until sync uploads
/// arrive (S5.3). Screens check [canEditProvider] first, so this only guards
/// against a missed entry point.
class ReadOnlyStoreException implements Exception {
  const ReadOnlyStoreException();

  @override
  String toString() => 'Editing arrives with sync uploads.';
}
