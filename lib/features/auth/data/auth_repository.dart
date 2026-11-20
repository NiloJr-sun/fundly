import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_identity.dart';

/// Signs the user in and out and reports who is signed in.
///
/// The default is [LocalOnlyAuthRepository]. `main` overrides
/// [authRepositoryProvider] with the Supabase one only when the build carries
/// the cloud configuration. Tests use a fake.
abstract class AuthRepository {
  /// Whether this build and platform can sign in at all.
  bool get canSignIn;

  /// The identity right now, known synchronously after start-up.
  AuthIdentity get currentIdentity;

  /// Every later identity change.
  Stream<AuthIdentity> watchIdentity();

  /// Signs in with Google. Throws [SignInCancelled] or [SignInFailed]; on
  /// success the new identity arrives through [watchIdentity]. On web the page
  /// navigates to Google and back instead of returning.
  Future<void> signInWithGoogle();

  /// Signs out on this device only. The user's local database is kept.
  Future<void> signOut();
}

/// No cloud configuration: always signed out, sign-in unavailable.
class LocalOnlyAuthRepository implements AuthRepository {
  const LocalOnlyAuthRepository();

  @override
  bool get canSignIn => false;

  @override
  AuthIdentity get currentIdentity => const SignedOut();

  @override
  Stream<AuthIdentity> watchIdentity() => const Stream.empty();

  @override
  Future<void> signInWithGoogle() async =>
      throw const SignInFailed('Sign-in is not available in this build.');

  @override
  Future<void> signOut() async {}
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const LocalOnlyAuthRepository(),
);

/// The current identity. The database, and everything built on it, follows
/// this provider.
final authIdentityProvider =
    NotifierProvider<AuthIdentityNotifier, AuthIdentity>(
      AuthIdentityNotifier.new,
    );

class AuthIdentityNotifier extends Notifier<AuthIdentity> {
  @override
  AuthIdentity build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.watchIdentity().listen((identity) {
      if (identity != state) state = identity;
    });
    ref.onDispose(subscription.cancel);
    return repository.currentIdentity;
  }
}
