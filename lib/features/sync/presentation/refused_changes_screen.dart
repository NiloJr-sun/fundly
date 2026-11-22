import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/sync/sync_rejections.dart';
import '../../../core/sync/synced_store.dart';
import '../../../core/widgets/centered_message.dart';
import 'refused_change_description.dart';

/// Lists changes the server refused (cloud sync S5.4), with what was tried,
/// so they can be redone by hand, and dismissed. Nothing is merged or
/// reapplied automatically.
class RefusedChangesScreen extends ConsumerWidget {
  const RefusedChangesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejections = ref.watch(refusedChangesProvider);
    final list = rejections.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refused changes'),
        actions: [
          if (list.isNotEmpty)
            TextButton(
              onPressed: () => _dismissAll(context, ref),
              child: const Text('Dismiss all'),
            ),
        ],
      ),
      body: switch (rejections) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No refused changes.',
        ),
        AsyncData(value: final list) => ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: Spacing.md),
              child: Text(
                'These changes were not saved to your account, and this '
                'device now shows what is saved there. Redo a change by hand '
                'if you still want it, then dismiss it.',
              ),
            ),
            for (final rejection in list)
              _RefusedChangeCard(
                key: ValueKey(rejection.batchId),
                rejection: rejection,
              ),
          ],
        ),
        AsyncError() => const CenteredMessage(
          'Refused changes could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _dismissAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss all refused changes?'),
        content: const Text(
          'They are removed from this list. Nothing else on this device or in '
          'your account changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Dismiss all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(syncedStoreProvider)?.database.dismissAllRejections();
  }
}

class _RefusedChangeCard extends ConsumerWidget {
  const _RefusedChangeCard({super.key, required this.rejection});

  final SyncRejection rejection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = describeRefusedChange(rejection);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: ExpansionTile(
        title: Text(description.title),
        subtitle: Text(
          '${description.reason} · '
          '${DateFormatter.localDate(rejection.rejectedAt)}',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.fromLTRB(
          Spacing.md,
          0,
          Spacing.md,
          Spacing.sm,
        ),
        children: [
          for (final (label, value) in description.details)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text('$label: $value'),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ref
                  .read(syncedStoreProvider)
                  ?.database
                  .dismissRejection(rejection.batchId),
              child: const Text('Dismiss'),
            ),
          ),
        ],
      ),
    );
  }
}
