/// Invite links (shared spaces C3, Decision C3-1): the web app's `/join`
/// page with the invite's secret after `#`, so the secret never reaches the
/// web server's logs.
const inviteLinkBase = 'https://fundly-budget.vercel.app/join';

/// The link an owner shares for the invite [secret].
String inviteLinkFor(String secret) => '$inviteLinkBase#$secret';

/// A secret is 64 hexadecimal characters (32 random bytes).
final _secret = RegExp(r'^[0-9a-f]{64}$');
final _secretInText = RegExp(
  r'(?:^|[^0-9a-z])([0-9a-f]{64})(?![0-9a-z])',
  caseSensitive: false,
);

/// The secret in what the user pasted into Join a space: the link, the link
/// inside a longer message, or the secret alone. Null when there is none,
/// or more than one different secret.
String? inviteSecretFromText(String text) {
  final found = {
    for (final match in _secretInText.allMatches(text))
      match.group(1)!.toLowerCase(),
  };
  return found.length == 1 ? found.single : null;
}

/// The secret when [url] is an invite link opened in the web app (its path
/// ends in `/join` and its fragment is a secret), else null.
String? inviteSecretFromUrl(Uri url) {
  final segments = url.pathSegments.where((segment) => segment.isNotEmpty);
  if (segments.isEmpty || segments.last != 'join') return null;
  final fragment = url.fragment.trim().toLowerCase();
  return _secret.hasMatch(fragment) ? fragment : null;
}
