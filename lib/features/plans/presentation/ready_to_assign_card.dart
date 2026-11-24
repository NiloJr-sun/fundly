import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../domain/plan_summary.dart';
import 'plans_providers.dart';

/// The selected month's carry over and money in, minus money moved out and
/// the month's assigned total. Negative amounts warn of overallocation without
/// preventing plan edits.
///
/// Tapping the card opens the month's transactions; the action button scrolls
/// down to the plan rows, where Assigned is edited.
class ReadyToAssignCard extends ConsumerWidget {
  const ReadyToAssignCard({super.key, required this.month});

  final CalendarMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAccounts = ref.watch(budgetAccountsProvider);
    final ready = ref.watch(readyToAssignProvider(month));
    final Widget body = switch (ready) {
      AsyncData(value: final value?) when budgetAccounts.isNotEmpty =>
        _ReadyToAssignDetails(
          value: value,
          budgetAccounts: budgetAccounts,
          onAssign: () => _scrollPastCard(context),
        ),
      AsyncData() => const _Message(
        "Choose a budget account in the Account tab to see what's ready "
        'to assign.',
      ),
      AsyncError() => const _Message('Could not be calculated.'),
      _ => const _Message('…'),
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // The filter takes one account, so this opens the whole month.
        onTap: budgetAccounts.isEmpty
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AllTransactionsScreen(
                    initialFilter: TransactionFilter(
                      dateRange: month.dateRange,
                    ),
                  ),
                ),
              ),
        child: Padding(padding: const EdgeInsets.all(Spacing.md), child: body),
      ),
    );
  }

  /// Scrolls the enclosing list so the plan rows below this card come into
  /// view. Does nothing when the list is too short to scroll.
  void _scrollPastCard(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    final card = context.findRenderObject();
    final viewport = scrollable?.context.findRenderObject();
    if (scrollable == null || card is! RenderBox || viewport == null) return;
    final position = scrollable.position;
    final cardBottom = card
        .localToGlobal(Offset(0, card.size.height), ancestor: viewport)
        .dy;
    final target = (position.pixels + cardBottom).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

/// The share of available money assigned, e.g. `99.8%` or `101%`, rounded to
/// one decimal place. Never shows `100%` unless every peso is assigned, so the
/// label agrees with the Balanced badge. Null when nothing is available.
@visibleForTesting
String? assignedPercentLabel({
  required Money assigned,
  required Money available,
}) {
  if (available.minorUnits <= 0) return null;
  var tenths = (assigned.minorUnits * 1000 / available.minorUnits).round();
  if (tenths == 1000 && assigned != available) {
    tenths = assigned.minorUnits < available.minorUnits ? 999 : 1001;
  }
  final whole = tenths ~/ 10;
  final decimal = tenths % 10;
  return decimal == 0 ? '$whole%' : '$whole.$decimal%';
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ready to assign', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Which of the three states the card is in.
enum _Balance { left, balanced, over }

class _ReadyToAssignDetails extends StatelessWidget {
  const _ReadyToAssignDetails({
    required this.value,
    required this.budgetAccounts,
    required this.onAssign,
  });

  final ReadyToAssign value;
  final List<Account> budgetAccounts;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = value.amount;
    final balance = money.isNegative
        ? _Balance.over
        : money.isZero
        ? _Balance.balanced
        : _Balance.left;
    final colors = theme.colorScheme;
    // Amounts follow the signed balance colours: positive green, zero
    // default, negative the palette's expense red.
    final amountColor = switch (balance) {
      _Balance.left => AppColors.of(context).positive,
      _Balance.balanced => colors.onSurface,
      _Balance.over => AppColors.of(context).expense,
    };
    final available = value.carryOver + value.moneyIn - value.movedOut;
    final percent = assignedPercentLabel(
      assigned: value.assigned,
      available: available,
    );
    final progress = available.minorUnits > 0
        ? (value.assigned.minorUnits / available.minorUnits).clamp(0.0, 1.0)
        : (value.assigned.minorUnits > 0 ? 1.0 : 0.0);
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ready to assign',
                style: theme.textTheme.titleMedium,
              ),
            ),
            _StatusBadge(balance: balance, amount: money),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          MoneyFormatter.format(money),
          key: const ValueKey('ready-to-assign-amount'),
          style: theme.textTheme.displaySmall?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: balance == _Balance.over
              ? AppColors.of(context).expense
              : colors.primary,
          backgroundColor: colors.surfaceContainerHighest,
        ),
        const SizedBox(height: Spacing.xs),
        // Wraps instead of overflowing on narrow screens or large text.
        Wrap(
          alignment: percent == null
              ? WrapAlignment.end
              : WrapAlignment.spaceBetween,
          spacing: Spacing.sm,
          children: [
            if (percent != null) Text('$percent assigned', style: caption),
            Text(
              '${MoneyFormatter.format(available)} available',
              style: caption,
            ),
          ],
        ),
        const Divider(height: Spacing.lg),
        _BreakdownRow(
          label: 'Carry over',
          amount: value.carryOver,
          muted: true,
        ),
        _BreakdownRow(label: '+ Money in this month', amount: value.moneyIn),
        if (!value.movedOut.isZero)
          _BreakdownRow(
            label: '− Moved out this month',
            amount: value.movedOut,
          ),
        _BreakdownRow(label: '− Assigned', amount: value.assigned),
        const SizedBox(height: Spacing.sm),
        _ActionButton(balance: balance, amount: money, onAssign: onAssign),
        const SizedBox(height: Spacing.sm),
        Text(_accountsLabel(budgetAccounts), style: caption),
      ],
    );
  }

  static String _accountsLabel(List<Account> accounts) {
    final names = accounts.map((account) => account.name).join(', ');
    return accounts.length == 1
        ? 'From $names'
        : 'From ${accounts.length} accounts · $names';
  }
}

/// Styled like the Plans status chips: Balanced matches Funded, Left to
/// assign matches Underfunded (action needed) and Over matches Overspent.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.balance, required this.amount});

  final _Balance balance;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (IconData? icon, label, background, foreground) = switch (balance) {
      _Balance.left => (
        null,
        'Left to assign',
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      _Balance.balanced => (
        Icons.check,
        'Balanced',
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      _Balance.over => (
        Icons.priority_high,
        'Over by ${MoneyFormatter.format(-amount)}',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: Spacing.xs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    this.muted = false,
  });

  final String label;
  final Money amount;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium;
    final amountStyle = theme.textTheme.bodyMedium?.copyWith(
      color: muted ? theme.colorScheme.onSurfaceVariant : null,
      fontWeight: muted ? null : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(MoneyFormatter.format(amount), style: amountStyle),
        ],
      ),
    );
  }
}

/// Uses the theme's button styles; only the over-assigned button switches to
/// the error colour.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.balance,
    required this.amount,
    required this.onAssign,
  });

  final _Balance balance;
  final Money amount;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return switch (balance) {
      _Balance.left => FilledButton(
        onPressed: onAssign,
        child: Text('Assign ${MoneyFormatter.format(amount)}'),
      ),
      // A status banner, not a button: there is nothing left to do.
      _Balance.balanced => Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Every peso has a job',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
      _Balance.over => OutlinedButton(
        onPressed: onAssign,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.of(context).expense,
          side: BorderSide(color: AppColors.of(context).expense),
        ),
        child: const Text('Fix over-assignment'),
      ),
    };
  }
}
