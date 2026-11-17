import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../categories/domain/category.dart';
import '../data/plan_repository.dart';
import '../domain/plan_validation_exception.dart';

Future<void> archivePlan(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Archive ${category.name}?'),
      content: const Text(
        'This hides the plan in every month and keeps its history. '
        'There must be no remaining allocation in the current or any future month.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Archive'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref
        .read(planRepositoryProvider)
        .setArchived(category.id, archived: true);
  } on PlanArchiveBlocked catch (error) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan still has allocated money'),
        scrollable: true,
        content: Text(
          [
            for (final entry in error.remainingByMonth.entries)
              '${DateFormatter.monthYear(entry.key.year, entry.key.month)}: ${MoneyFormatter.format(entry.value)}',
            '\nReduce Assigned for these months to release the remaining allocation, then try again.',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This plan could not be archived.')),
    );
  }
}
