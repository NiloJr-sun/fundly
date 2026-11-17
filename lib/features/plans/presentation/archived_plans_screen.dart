import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/widgets/centered_message.dart';
import '../../categories/presentation/category_display.dart';
import '../data/plan_repository.dart';
import '../domain/plan_deletion.dart';
import '../domain/plan_summary.dart';
import 'plan_activity.dart';
import 'plan_month_bar.dart';
import 'plan_row.dart';
import 'plans_providers.dart';

/// All archived Plans rows. The month selector allows browsing their history.
class ArchivedPlansScreen extends ConsumerWidget {
  const ArchivedPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedPlanMonthProvider);
    final summaries = ref.watch(archivedPlanSummariesProvider(month));
    return Scaffold(
      appBar: AppBar(title: const Text('Archived plans')),
      body: Column(
        children: [
          const PlanMonthBar(),
          Expanded(
            child: switch (summaries) {
              AsyncData(value: final rows) when rows.isEmpty =>
                const CenteredMessage('No archived plans.'),
              AsyncData(value: final rows) => ListView(
                children: [
                  for (final row in rows)
                    ListTile(
                      title: Text(row.category.name),
                      subtitle: Text(planGroupLabel(row.category.planGroup)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _ArchivedPlanDetailScreen(
                            categoryId: row.category.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AsyncError() => const CenteredMessage(
                'Archived plans could not be loaded.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _ArchivedPlanDetailScreen extends ConsumerStatefulWidget {
  const _ArchivedPlanDetailScreen({required this.categoryId});

  final int categoryId;

  @override
  ConsumerState<_ArchivedPlanDetailScreen> createState() =>
      _ArchivedPlanDetailScreenState();
}

class _ArchivedPlanDetailScreenState
    extends ConsumerState<_ArchivedPlanDetailScreen> {
  bool _saving = false;
  bool _deleting = false;

  Future<void> _unarchive() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(planRepositoryProvider)
          .setArchived(widget.categoryId, archived: false);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This plan could not be unarchived.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $name plan?'),
        content: const Text(
          'This permanently removes this plan and its saved targets for every month. '
          'Your category and account are kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _deleting = true;
    });
    try {
      await ref
          .read(planRepositoryProvider)
          .deletePermanently(widget.categoryId);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('$name plan deleted.')));
    } on PlanDeletionException catch (error) {
      if (!mounted) return;
      ref.invalidate(planDeletionStatusProvider(widget.categoryId));
      messenger.showSnackBar(
        SnackBar(content: Text(_deletionMessage(error.status))),
      );
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('This plan could not be deleted.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _deleting = false;
        });
      }
    }
  }

  static String _deletionMessage(PlanDeletionStatus status) => switch (status) {
    PlanDeletionStatus.hasAssignedMoney =>
      'Assigned must be zero in every month before this plan can be deleted.',
    PlanDeletionStatus.hasActivity =>
      'Plans with spending or payment history cannot be permanently deleted.',
    PlanDeletionStatus.notArchived => 'Archive this plan before deleting it.',
    PlanDeletionStatus.alreadyDeleted => 'This plan has already been deleted.',
    PlanDeletionStatus.categoryNotFound => 'This plan no longer exists.',
    PlanDeletionStatus.categoryNotSpending =>
      'Only spending plans can be deleted.',
    PlanDeletionStatus.allowed => 'This plan could not be deleted.',
  };

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedPlanMonthProvider);
    final summaries = ref.watch(archivedPlanSummariesProvider(month));
    return Scaffold(
      appBar: AppBar(title: const Text('Archived plan')),
      body: switch (summaries) {
        AsyncData(value: final rows) => _details(rows),
        AsyncError() => const CenteredMessage('This plan could not be loaded.'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _details(List<CategoryPlanSummary> rows) {
    final matches = rows
        .where((row) => row.category.id == widget.categoryId)
        .toList();
    if (matches.isEmpty) {
      return const CenteredMessage('This plan is no longer archived.');
    }
    final summary = matches.single;
    final category = summary.category;
    final month = ref.watch(selectedPlanMonthProvider);
    final deletion = ref.watch(planDeletionStatusProvider(widget.categoryId));
    final canDelete =
        deletion is AsyncData<PlanDeletionStatus> &&
        deletion.value == PlanDeletionStatus.allowed;
    final hint = switch (deletion) {
      AsyncData(value: final status) =>
        status == PlanDeletionStatus.allowed ? null : _deletionMessage(status),
      AsyncError() => 'Could not check whether this plan can be deleted.',
      _ => 'Checking whether this plan can be deleted…',
    };
    final errorColor = Theme.of(context).colorScheme.error;
    return ListView(
      children: [
        const PlanMonthBar(),
        PlanRow(
          summary: summary,
          onEdit: null,
          onActivityTap: () => showPlanActivity(context, month, category),
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category.isArchived
                    ? category.linkedAccountId != null
                          ? 'This account is archived. Unarchive it in the Account tab first.'
                          : 'This category is archived. Unarchive it in Categories first.'
                    : 'This plan is archived in every month. Unarchive it to edit its allocations.',
              ),
              const SizedBox(height: Spacing.md),
              FilledButton.icon(
                onPressed: _saving || category.isArchived ? null : _unarchive,
                icon: const Icon(Icons.unarchive_outlined),
                label: Text(
                  _saving && !_deleting ? 'Unarchiving…' : 'Unarchive plan',
                ),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: canDelete && !_saving
                      ? BorderSide(color: errorColor)
                      : null,
                ),
                onPressed: canDelete && !_saving
                    ? () => _delete(category.name)
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: Text(_deleting ? 'Deleting…' : 'Delete permanently'),
              ),
              if (hint != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(hint),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
