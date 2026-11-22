import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/time/clock_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../auth/domain/greeting.dart';
import '../../auth/presentation/google_sign_in_button.dart';
import '../../auth/presentation/sign_in_actions.dart';
import '../../sync/presentation/sync_status_line.dart';

/// The top of the Profile tab: a time-of-day greeting.
///
/// Signed in: "Good evening, Nilo", "Signed in as …" and the sync status.
/// As a guest: "Good evening", "Using Fundly as a guest" and, in builds that
/// can sign in, Continue with Google.
class ProfileGreetingCard extends ConsumerStatefulWidget {
  const ProfileGreetingCard({super.key});

  @override
  ConsumerState<ProfileGreetingCard> createState() =>
      _ProfileGreetingCardState();
}

class _ProfileGreetingCardState extends ConsumerState<ProfileGreetingCard> {
  bool _signingIn = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _signingIn = true);
    await signInWithGoogle(context, ref);
    // On success the app rebuilds for the new user; otherwise allow a retry.
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(authIdentityProvider);
    final canSignIn = ref.watch(authRepositoryProvider).canSignIn;
    final greeting = greetingFor(ref.watch(clockProvider)().toLocal());
    final theme = Theme.of(context);

    final String title;
    final String subtitle;
    final Widget avatar;
    if (identity is SignedIn) {
      final firstName = identity.firstName;
      final who = identity.email.isEmpty ? 'your account' : identity.email;
      title = firstName.isEmpty ? greeting : '$greeting, $firstName';
      subtitle = 'Signed in as $who';
      avatar = _Avatar(child: Text(_initial(firstName, identity.email)));
    } else {
      title = greeting;
      subtitle = 'Using Fundly as a guest';
      avatar = const _Avatar(child: Icon(Icons.person_outline));
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.dialogTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (identity is SignedIn) ...[
                      const SizedBox(height: Spacing.xs),
                      const SyncStatusLine(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (identity is! SignedIn && canSignIn) ...[
            const SizedBox(height: Spacing.md),
            GoogleSignInButton(
              onPressed: _signingIn ? null : _continueWithGoogle,
              busy: _signingIn,
            ),
          ],
        ],
      ),
    );
  }

  /// The avatar letter: the name's first letter, else the email's, else "?".
  static String _initial(String firstName, String email) {
    final source = firstName.isNotEmpty ? firstName : email;
    return source.isEmpty ? '?' : source.characters.first.toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        child: child,
      ),
    );
  }
}
