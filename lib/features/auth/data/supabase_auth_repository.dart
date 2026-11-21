import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/cloud_config.dart';
import '../domain/auth_identity.dart';
import 'auth_repository.dart';

/// Maps a Supabase auth event to the identity it leaves the app in.
///
/// Session policy (S4 Decision 4): a restored session counts as signed in even
/// when its access token has expired, so the user's data stays usable offline;
/// Supabase refreshes the token when the network returns. Only an explicit
/// sign-out, or Supabase rejecting the refresh token, emits `signedOut`.
AuthIdentity identityFromAuthState(AuthState state) {
  if (state.event == AuthChangeEvent.signedOut) return const SignedOut();
  return identityFromSession(state.session);
}

AuthIdentity identityFromSession(Session? session) {
  final user = session?.user;
  if (user == null) return const SignedOut();
  final metadata = user.userMetadata ?? const {};
  // Google fills full_name (and name) in Supabase's user metadata.
  final name = metadata['full_name'] ?? metadata['name'];
  return SignedIn(
    userId: user.id,
    email: user.email ?? '',
    name: name is String ? name.trim() : '',
  );
}

/// Supabase Auth with Google: native sign-in on iOS, OAuth redirect on web.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._config);

  final SupabaseClient _client;
  final CloudConfig _config;

  /// The raw nonce for this app run. `GoogleSignIn.initialize` may only be
  /// called once, so the nonce is fixed when it is first needed; Supabase
  /// still checks the ID token against it on every sign-in.
  String? _rawNonce;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get canSignIn => kIsWeb || _isIos;

  @override
  AuthIdentity get currentIdentity =>
      identityFromSession(_client.auth.currentSession);

  @override
  Stream<AuthIdentity> watchIdentity() => _client.auth.onAuthStateChange
      .map(identityFromAuthState)
      // A failed background refresh (for example, offline) is reported as a
      // stream error. It must not change the identity.
      .handleError((Object _) {});

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) return _signInOnWeb();
    if (_isIos) return _signInOnIos();
    throw const SignInFailed('Sign-in is not available on this device yet.');
  }

  Future<void> _signInOnWeb() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${Uri.base.origin}/',
      );
    } on AuthException catch (error) {
      throw SignInFailed(error.message);
    }
  }

  Future<void> _signInOnIos() async {
    if (_config.googleIosClientId.isEmpty ||
        _config.googleWebClientId.isEmpty) {
      throw const SignInFailed('Google sign-in is not set up in this build.');
    }
    final google = GoogleSignIn.instance;
    if (_rawNonce == null) {
      final rawNonce = _newNonce();
      await google.initialize(
        clientId: _config.googleIosClientId,
        serverClientId: _config.googleWebClientId,
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      _rawNonce = rawNonce;
    }

    final String? idToken;
    try {
      final account = await google.authenticate();
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelled();
      }
      throw const SignInFailed('Google sign-in did not finish.');
    }
    if (idToken == null) {
      throw const SignInFailed('Google did not return a sign-in token.');
    }

    try {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: _rawNonce,
      );
    } on AuthException catch (error) {
      throw SignInFailed(error.message);
    } on Object {
      throw const SignInFailed(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    // Local scope: other devices stay signed in. The session is removed
    // before the server call, so this also works offline.
    await _client.auth.signOut();
    if (_rawNonce != null) {
      // Lets the next sign-in choose a different Google account.
      await GoogleSignIn.instance.signOut();
    }
  }

  static String _newNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
