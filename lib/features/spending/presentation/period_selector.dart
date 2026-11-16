import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_range.dart';
import 'spending_providers.dart';

String periodPresetLabel(PeriodPreset preset) => switch (preset) {
  PeriodPreset.thisMonth => 'This month',
  PeriodPreset.lastMonth => 'Last month',
  PeriodPreset.custom => 'Custom range',
};

/// Chips for This month, Last month and a custom date range.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final current = ref.read(currentPeriodProvider);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: current.start.toLocalDateTime(),
        end: current.end.toLocalDateTime(),
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return; // Cancelled: keep the previous period.
    ref
        .read(selectedPeriodProvider.notifier)
        .selectCustom(
          DateRange(
            CalendarDate.fromDateTime(picked.start),
            CalendarDate.fromDateTime(picked.end),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPeriodProvider).preset;
    final notifier = ref.read(selectedPeriodProvider.notifier);
    return Wrap(
      spacing: Spacing.sm,
      children: [
        ChoiceChip(
          label: Text(periodPresetLabel(PeriodPreset.thisMonth)),
          selected: selected == PeriodPreset.thisMonth,
          onSelected: (_) => notifier.selectThisMonth(),
        ),
        ChoiceChip(
          label: Text(periodPresetLabel(PeriodPreset.lastMonth)),
          selected: selected == PeriodPreset.lastMonth,
          onSelected: (_) => notifier.selectLastMonth(),
        ),
        ChoiceChip(
          label: const Text('Custom'),
          selected: selected == PeriodPreset.custom,
          // Re-tapping Custom lets the user change the range.
          onSelected: (_) => _pickCustom(context, ref),
        ),
      ],
    );
  }
}
