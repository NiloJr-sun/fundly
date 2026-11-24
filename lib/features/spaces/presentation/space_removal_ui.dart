import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../sync/presentation/refused_changes_screen.dart';
import '../data/active_space.dart';
import '../data/device_space_stores.dart';
import '../data/space_removals.dart';
import 'space_providers.dart';

/// What the notice says once the active space left the user and was deleted
/// from this device (shared spaces C3, Decision C3-6).
String spaceLeftNotice(String name) =>
    "You're no longer a member of ${name.isEmpty ? 'a space' : name}. It "
    'was removed from this device, and Personal is shown.';

/// Shows [SpaceRemovalState.notice] once, then clears it.
class SpaceNoticeHandler extends ConsumerWidget {
  const SpaceNoticeHandler({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(spaceRemovalsProvider.select((s) => s.notice));
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(spaceLeftNotice(notice))));
        ref.read(spaceRemovalsProvider.notifier).dismissNotice();
      });
    }
    return child;
  }
}

/// Asks first, then deletes a Removed space's store from this device. Its
/// unsent and refused changes go with it.
Future<void> removeSpaceFromDevice(
  BuildContext context,
  WidgetRef ref,
  DeviceSpace space,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove ${space.name} from this device?'),
      content: const Text(
        'Its changes that never reached the server are deleted with it. '
        'Export a backup or note them under Refused changes first if you '
        'need them.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref
        .read(spaceRemovalsProvider.notifier)
        .removeFromDevice(space.spaceId);
  } on Object {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${space.name} could not be removed from this device. Close any '
          'other tab showing it and try again.',
        ),
      ),
    );
  }
}

/// Above the tabs while the active space is a Removed one: says why it is
/// read-only and offers its refused changes and removal.
class RemovedSpaceBanner extends ConsumerWidget {
  const RemovedSpaceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(activeSpaceRemovedProvider)) return const SizedBox.shrink();
    final activeId = ref.watch(activeSpaceIdProvider);
    final space = ref
        .watch(spaceRemovalsProvider)
        .removed
        .firstWhere((space) => space.spaceId == activeId);
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Card(
        key: const Key('removed-space-banner'),
        margin: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.sm,
          Spacing.md,
          0,
        ),
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.sm,
            Spacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You're no longer a member of ${space.name}. It stays here, "
                'read-only, because some changes never reached the server.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RefusedChangesScreen(),
                      ),
                    ),
                    child: const Text('Refused changes'),
                  ),
                  TextButton(
                    onPressed: () => removeSpaceFromDevice(context, ref, space),
                    child: const Text('Remove from this device'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
