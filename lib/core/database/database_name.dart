import '../../features/auth/domain/auth_identity.dart';

/// The original on-device database, used while signed out. Never renamed.
const localDatabaseName = 'fundly';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// The local database for [identity]: one per signed-in user, so users never
/// see each other's records, and the signed-out data is never attached to a
/// Google account automatically.
///
/// The Supabase user ID becomes part of a file name (or a browser database
/// name), so anything other than a UUID is rejected.
String databaseNameFor(AuthIdentity identity) => switch (identity) {
  SignedOut() => localDatabaseName,
  SignedIn(:final userId) => 'fundly_user_${_checkedUserId(userId)}',
};

String _checkedUserId(String userId) {
  final normalized = userId.toLowerCase();
  if (!_uuid.hasMatch(normalized)) {
    throw ArgumentError.value(userId, 'userId', 'is not a UUID');
  }
  return normalized;
}
