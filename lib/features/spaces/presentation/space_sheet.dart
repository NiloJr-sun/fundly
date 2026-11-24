import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../data/active_space.dart';
import '../data/space_directory.dart';
import '../domain/space.dart';
import 'space_actions.dart';
import 'space_name_dialog.dart';
import 'space_providers.dart';

/// The user's spaces: tap one to switch, or create a new one (shared spaces
/// C2, option A); each row's ⋮ menu has Members, Invite, Rename, Leave and
/// Delete as the role allows (C3). Opened from the Profile card.
Future<void> showSpaceSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const SpaceSheet(),
);

class SpaceSheet extends ConsumerWidget {
  const SpaceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider).value ?? const [];
    final activeId = ref.watch(activeSpaceIdProvider);
    final theme = Theme.of(context);

    Future<void> choose(Space space) async {
      Navigator.of(context).pop();
      if (space.id != activeId) {
        await ref.read(activeSpaceIdProvider.notifier).select(space.id);
      }
    }

    Future<void> create() async {
      final navigator = Navigator.of(context);
      final created = await createSpace(context);
      if (created != null) navigator.pop();
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Spacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.sm,
              ),
              child: Text('Your spaces', style: theme.textTheme.titleMedium),
            ),
            if (spaces.isEmpty)
              const ListTile(
                leading: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Loading your spaces…'),
              ),
            for (final space in spaces)
              ListTile(
                key: ValueKey('space-${space.id}'),
                leading: Icon(
                  space.id == activeId
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: space.id == activeId
                      ? theme.colorScheme.primary
                      : null,
                ),
                title: Text(space.name),
                subtitle: Text(
                  space.isPersonal
                      ? '${roleLabel(space.role)} · Personal'
                      : roleLabel(space.role),
                ),
                selected: space.id == activeId,
                trailing: SpaceActionsButton(space: space),
                onTap: () => choose(space),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create space'),
              subtitle: const Text('Needs a connection'),
              onTap: create,
            ),
          ],
        ),
      ),
    );
  }
}

/// The row at the bottom of the signed-in Profile card: the active space and
/// role, opening [SpaceSheet].
class SpaceSwitcherRow extends ConsumerWidget {
  const SpaceSwitcherRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(activeSpaceProvider);
    final theme = Theme.of(context);
    return InkWell(
      key: const Key('space-switcher'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => showSpaceSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(Icons.layers_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: space?.name ?? 'Loading space…',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (space != null)
                      TextSpan(
                        text: ' · ${roleLabel(space.role)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
