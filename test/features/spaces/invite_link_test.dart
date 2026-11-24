import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/spaces/domain/invite_link.dart';

void main() {
  final secret = 'ab12' * 16;

  test('the link carries the secret after #', () {
    expect(
      inviteLinkFor(secret),
      'https://fundly-budget.vercel.app/join#$secret',
    );
  });

  group('pasted into Join a space', () {
    test('the link, the link inside a message, or the secret alone', () {
      expect(inviteSecretFromText(inviteLinkFor(secret)), secret);
      expect(
        inviteSecretFromText(
          'Join my space on Fundly:\n${inviteLinkFor(secret)} (expires in '
          '7 days)',
        ),
        secret,
      );
      expect(inviteSecretFromText('  $secret \n'), secret);
    });

    test('upper case becomes the lower case the server expects', () {
      expect(inviteSecretFromText(secret.toUpperCase()), secret);
    });

    test('nothing, a short or long run, or two different secrets: none', () {
      expect(inviteSecretFromText(''), isNull);
      expect(inviteSecretFromText('hello'), isNull);
      expect(inviteSecretFromText(secret.substring(1)), isNull);
      expect(inviteSecretFromText('${secret}0'), isNull);
      expect(inviteSecretFromText('${secret}g'), isNull);
      expect(inviteSecretFromText('$secret ${'cd34' * 16}'), isNull);
    });

    test('the same secret twice is still one', () {
      expect(inviteSecretFromText('$secret ${inviteLinkFor(secret)}'), secret);
    });
  });

  group('opened in the web app', () {
    test('/join with a secret fragment', () {
      expect(inviteSecretFromUrl(Uri.parse(inviteLinkFor(secret))), secret);
      expect(
        inviteSecretFromUrl(Uri.parse('http://localhost:5000/join/#$secret')),
        secret,
      );
    });

    test('another page, no fragment or a malformed one: none', () {
      expect(
        inviteSecretFromUrl(
          Uri.parse('https://fundly-budget.vercel.app/#$secret'),
        ),
        isNull,
      );
      expect(
        inviteSecretFromUrl(Uri.parse('https://fundly-budget.vercel.app/join')),
        isNull,
      );
      expect(
        inviteSecretFromUrl(
          Uri.parse('https://fundly-budget.vercel.app/join#abc'),
        ),
        isNull,
      );
    });
  });
}
