import 'dart:async';

import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';

/// An [AuthRepository] whose identity the test controls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.canSignIn = true,
    AuthIdentity initial = const SignedOut(),
  }) : _identity = initial;

  final _changes = StreamController<AuthIdentity>.broadcast();
  AuthIdentity _identity;

  @override
  final bool canSignIn;

  /// Thrown by [signInWithGoogle] when set.
  Object? signInError;

  /// The identity a successful [signInWithGoogle] switches to.
  AuthIdentity? identityAfterSignIn;

  int signInCalls = 0;
  int signOutCalls = 0;

  /// Simulates Supabase reporting a new identity.
  void emit(AuthIdentity identity) {
    _identity = identity;
    _changes.add(identity);
  }

  @override
  AuthIdentity get currentIdentity => _identity;

  @override
  Stream<AuthIdentity> watchIdentity() => _changes.stream;

  @override
  Future<void> signInWithGoogle() async {
    signInCalls++;
    final error = signInError;
    if (error != null) throw error;
    final next = identityAfterSignIn;
    if (next != null) emit(next);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(const SignedOut());
  }
}
