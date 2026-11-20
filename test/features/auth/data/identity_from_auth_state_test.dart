import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/auth/data/supabase_auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d';

Session session({String? email = 'a@test.com', int? expiresAt}) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: userId,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-11-20T00:00:00Z',
    email: email,
  ),
)..expiresAt = expiresAt;

/// S4 Decision 4: who the app treats as signed in after each auth event.
void main() {
  const signedIn = SignedIn(userId: userId, email: 'a@test.com');

  test('no saved session at start-up is signed out', () {
    expect(
      identityFromAuthState(
        const AuthState(AuthChangeEvent.initialSession, null),
      ),
      const SignedOut(),
    );
  });

  test('a restored session is signed in', () {
    expect(
      identityFromAuthState(
        AuthState(AuthChangeEvent.initialSession, session()),
      ),
      signedIn,
    );
  });

  test('a restored session with an expired access token stays signed in '
      '(offline use keeps the user and their data)', () {
    final expired = session(expiresAt: 1);
    expect(expired.isExpired, isTrue);
    expect(
      identityFromAuthState(AuthState(AuthChangeEvent.initialSession, expired)),
      signedIn,
    );
  });

  test('sign-in and token refresh are signed in', () {
    for (final event in [
      AuthChangeEvent.signedIn,
      AuthChangeEvent.tokenRefreshed,
      AuthChangeEvent.userUpdated,
    ]) {
      expect(
        identityFromAuthState(AuthState(event, session())),
        signedIn,
        reason: event.name,
      );
    }
  });

  test('sign-out or a revoked session is signed out', () {
    expect(
      identityFromAuthState(const AuthState(AuthChangeEvent.signedOut, null)),
      const SignedOut(),
    );
    // Even if an event carried a session, signedOut wins.
    expect(
      identityFromAuthState(AuthState(AuthChangeEvent.signedOut, session())),
      const SignedOut(),
    );
  });

  test('a user without an email is still signed in', () {
    expect(
      identityFromSession(session(email: null)),
      const SignedIn(userId: userId, email: ''),
    );
  });
}
