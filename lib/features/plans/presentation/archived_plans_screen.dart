import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/widgets/centered_message.dart';
import '../../categories/presentation/category_display.dart';
import '../data/plan_repository.dart';
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
                label: Text(_saving ? 'Unarchiving…' : 'Unarchive plan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
