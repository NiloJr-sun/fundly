import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(CalendarDate(2026, 1, 15))],
    );
  });

  tearDown(() => container.dispose());

  SelectedPeriodNotifier notifier() =>
      container.read(selectedPeriodProvider.notifier);

  test('defaults to the current calendar month', () {
    expect(
      container.read(selectedPeriodProvider),
      PeriodSelection(
        PeriodPreset.thisMonth,
        DateRange(CalendarDate(2026, 1, 1), CalendarDate(2026, 1, 31)),
      ),
    );
  });

  test('last month crosses the year boundary', () {
    notifier().selectLastMonth();

    expect(
      container.read(currentPeriodProvider),
      DateRange(CalendarDate(2025, 12, 1), CalendarDate(2025, 12, 31)),
    );
  });

  test('custom keeps the given range', () {
    final range = DateRange(CalendarDate(2026, 1, 5), CalendarDate(2026, 1, 9));

    notifier().selectCustom(range);

    expect(
      container.read(selectedPeriodProvider),
      PeriodSelection(PeriodPreset.custom, range),
    );
  });

  test('this month resets a custom range', () {
    notifier().selectCustom(
      DateRange(CalendarDate(2025, 1, 1), CalendarDate(2025, 1, 2)),
    );

    notifier().selectThisMonth();

    expect(
      container.read(selectedPeriodProvider).preset,
      PeriodPreset.thisMonth,
    );
  });
}
