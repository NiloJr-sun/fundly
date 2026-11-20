/// Who is using the app: nobody (local use) or a signed-in cloud user.
///
/// The identity decides which local database is open (see
/// `databaseNameFor`). Two identities are equal when they would show the same
/// data, so a token refresh for the same user changes nothing.
sealed class AuthIdentity {
  const AuthIdentity();
}

/// Signed out: the app uses the original on-device database.
final class SignedOut extends AuthIdentity {
  const SignedOut();

  @override
  bool operator ==(Object other) => other is SignedOut;

  @override
  int get hashCode => (SignedOut).hashCode;
}

/// Signed in to Supabase as [userId] (a UUID), with [email] for display.
final class SignedIn extends AuthIdentity {
  const SignedIn({required this.userId, required this.email});

  final String userId;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is SignedIn && other.userId == userId && other.email == email;

  @override
  int get hashCode => Object.hash(userId, email);
}

/// Sign-in was cancelled by the user; nothing changed.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// Sign-in failed; nothing changed. [message] is shown to the user.
class SignInFailed implements Exception {
  const SignInFailed(this.message);

  final String message;

  @override
  String toString() => 'SignInFailed: $message';
}
