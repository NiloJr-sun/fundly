import 'dart:js_interop';

import '../domain/invite_link.dart';

const _key = 'fundly.pendingInvite';

@JS('history')
external _History get _history;

extension type _History(JSObject _) implements JSObject {
  external void replaceState(JSAny? data, String unused, String url);
}

@JS('sessionStorage')
external _Storage get _sessionStorage;

extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

/// The invite this tab was opened for, if any. A `/join#<secret>` address is
/// replaced by the app's root at once, so the secret never stays in the
/// address bar or history; it is kept in this tab's session storage instead,
/// which survives the Google sign-in redirect and ends with the tab.
String? takeInviteSecretFromPage() {
  final secret = inviteSecretFromUrl(Uri.base);
  if (secret != null) {
    _sessionStorage.setItem(_key, secret);
    _history.replaceState(null, '', '/');
  }
  return _sessionStorage.getItem(_key);
}

/// Called once the invite was shown, so a reload does not show it again.
void forgetPendingInviteSecret() => _sessionStorage.removeItem(_key);
