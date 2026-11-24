import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'space_providers.dart';

/// A tab's app bar title, with the active space's name under it when the user
/// has more than one space (shared spaces C2, Decision C2-7).
class ScreenTitle extends ConsumerWidget {
  const ScreenTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(shownSpaceNameProvider);
    if (space == null) return Text(title);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(
          space,
          key: const Key('screen-title-space'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
