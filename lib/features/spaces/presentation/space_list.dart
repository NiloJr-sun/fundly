import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../data/active_space.dart';
import '../data/space_directory.dart';
import '../data/space_removals.dart';
import 'join_space.dart';
import 'space_actions.dart';
import 'space_name_dialog.dart';
import 'space_providers.dart';
import 'space_removal_ui.dart';

/// The Your spaces section at the bottom of the signed-in Account & Spaces
/// card. Collapsed, its header names the active space and role; tap it to
/// list every space. Tap a row to switch to that space; each row's ⋮ menu has
/// Members, Invite, Rename, Leave and Delete as the role allows (C3). Below
/// the list: create or join a space.
///
/// Switching changes [activeSpaceIdProvider]; the app then rebuilds from the
/// home tabs with that space's records (see `FundlyApp`), so the section
/// starts collapsed again.
class SpaceSection extends ConsumerStatefulWidget {
  const SpaceSection({super.key});

  @override
  ConsumerState<SpaceSection> createState() => _SpaceSectionState();
}

class _SpaceSectionState extends ConsumerState<SpaceSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSpaceProvider);
    final removedActive = ref.watch(activeSpaceRemovedProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = active != null
        ? '${active.name} · ${roleLabel(active.role)}'
        : removedActive
        ? 'Removed space · read-only'
        : 'Loading space…';

    // Transparent Material so row highlights and ripples show on the card.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              key: const Key('space-switcher'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.layers_outlined, color: colors.primary),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR SPACES',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded ? const _SpaceList() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Every space, then the create and join actions.
class _SpaceList extends StatelessWidget {
  const _SpaceList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.xs),
        const _SpaceRows(withActions: true),
        const Divider(height: Spacing.md),
        _SpaceActionRow(
          icon: Icons.add,
          title: 'Create a new space',
          subtitle: 'Needs a connection',
          // The dialog creates the space and switches to it.
          onTap: () => createSpace(context),
        ),
        _SpaceActionRow(
          icon: Icons.group_add_outlined,
          title: 'Join a space',
          subtitle: 'Paste an invite link',
          onTap: () => joinSpace(context),
        ),
      ],
    );
  }
}

/// Opens a sheet listing every space, from a long press on the Profile tab.
/// Tap a space to switch to it; managing spaces stays on the Profile tab.
Future<void> showSpaceSwitcherSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            0,
            Spacing.md,
            Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Text(
                  'Switch space',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Close the sheet first: switching rebuilds the app from its
              // home tabs, which would drop the sheet's route.
              _SpaceRows(
                withActions: false,
                beforeSwitch: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );

/// A row per space, then a row per space removed from this user but still
/// on this device. Tap a row to switch to it. [withActions] adds each row's
/// ⋮ menu (and the remove button on removed spaces); [beforeSwitch] runs
/// before switching to another space.
class _SpaceRows extends ConsumerWidget {
  const _SpaceRows({required this.withActions, this.beforeSwitch});

  final bool withActions;
  final VoidCallback? beforeSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider).value ?? const [];
    final removed = [
      for (final removed in ref.watch(spaceRemovalsProvider).removed)
        if (!spaces.any((space) => space.id == removed.spaceId)) removed,
    ];
    final activeId = ref.watch(activeSpaceIdProvider);
    final theme = Theme.of(context);

    Future<void> choose(String spaceId) async {
      beforeSwitch?.call();
      if (spaceId != activeId) {
        await ref.read(activeSpaceIdProvider.notifier).select(spaceId);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (spaces.isEmpty && removed.isEmpty)
          // Static, not a spinner: the list may wait a long time offline.
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 40,
              child: Icon(
                Icons.cloud_download_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            title: const Text('Loading your spaces…'),
          ),
        for (final space in spaces)
          _SpaceTile(
            key: ValueKey('space-${space.id}'),
            icon: space.isPersonal
                ? Icons.person_outline
                : Icons.groups_outlined,
            name: space.name,
            details: space.isPersonal
                ? '${roleLabel(space.role)} · Personal'
                : roleLabel(space.role),
            active: space.id == activeId,
            trailing: withActions ? SpaceActionsButton(space: space) : null,
            onTap: () => choose(space.id),
          ),
        for (final space in removed)
          _SpaceTile(
            key: ValueKey('removed-space-${space.spaceId}'),
            icon: Icons.remove_circle_outline,
            iconColor: theme.colorScheme.error,
            name: space.name,
            details: 'Removed · read-only on this device',
            active: space.spaceId == activeId,
            trailing: withActions
                ? IconButton(
                    tooltip: 'Remove ${space.name} from this device',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => removeSpaceFromDevice(context, ref, space),
                  )
                : null,
            onTap: () => choose(space.spaceId),
          ),
      ],
    );
  }
}

/// One space: its icon, name, an Active badge on the space being shown, and
/// the role. The whole row switches to the space.
class _SpaceTile extends StatelessWidget {
  const _SpaceTile({
    super.key,
    required this.icon,
    required this.name,
    required this.details,
    required this.active,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String name;
  final String details;
  final bool active;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Only the Active badge marks the row; no highlight. Screen readers
    // still hear it as selected.
    return Semantics(
      selected: active,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.only(left: Spacing.sm),
        minTileHeight: 64,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? colors.primary),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w600 : null,
                  color: active ? colors.onSurface : null,
                ),
              ),
            ),
            if (active) ...[
              const SizedBox(width: Spacing.sm),
              const _ActiveBadge(),
            ],
          ],
        ),
        subtitle: Text(
          details,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// A small "Active" pill on the space whose records the app shows.
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Active',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A quiet action under the space list, such as Create a new space.
class _SpaceActionRow extends StatelessWidget {
  const _SpaceActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      leading: SizedBox(width: 40, child: Icon(icon, color: colors.primary)),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: colors.primary),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}
