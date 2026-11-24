import '../../features/auth/domain/auth_identity.dart';

/// The original on-device database, used while signed out. Never renamed.
const localDatabaseName = 'fundly';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// The local database for [identity]: the signed-out one, or the signed-in
/// user's synchronized store (cloud sync S5.2). One per user, so users never
/// see each other's records, and the signed-out data is never attached to a
/// Google account automatically.
///
/// The Supabase user ID becomes part of a file name (or a browser database
/// name), so anything other than a UUID is rejected.
String databaseNameFor(AuthIdentity identity) => switch (identity) {
  SignedOut() => localDatabaseName,
  SignedIn(:final userId) => 'fundly_sync_${_checkedUserId(userId)}',
};

/// The synchronized store of [userId]'s space [spaceId] (shared spaces C2).
/// Personal (whose id is the user's) keeps the name it has had since S5.2,
/// so upgrading never moves its data; any other space gets its own store.
String syncedDatabaseNameFor(String userId, String spaceId) {
  final user = _checkedUserId(userId);
  final space = _checkedUserId(spaceId);
  return space == user ? 'fundly_sync_$user' : 'fundly_sync_${user}_$space';
}

/// The S4 preview database of [userId], which the synchronized store replaces
/// and deletes (S4 Decision 1).
String previewDatabaseNameFor(String userId) =>
    'fundly_user_${_checkedUserId(userId)}';

String _checkedUserId(String userId) {
  final normalized = userId.toLowerCase();
  if (!_uuid.hasMatch(normalized)) {
    throw ArgumentError.value(userId, 'userId', 'is not a UUID');
  }
  return normalized;
}
