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
