import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../data/auth_repository.dart';
import '../domain/auth_identity.dart';

/// "Signed in as … · Not syncing yet" while signed in; nothing otherwise.
class SignedInBanner extends ConsumerWidget {
  const SignedInBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(authIdentityProvider);
    if (identity is! SignedIn) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final who = identity.email.isEmpty ? 'your account' : identity.email;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Signed in as $who · Not syncing yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
