import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import 'assign_draft.dart';

/// The panel for editing a row's Assigned amount in place: Activity, Details
/// and Cancel, an optional hint toward the Target, and a calculator keypad.
class AssignPanel extends StatelessWidget {
  const AssignPanel({
    super.key,
    required this.onKey,
    required this.onDone,
    required this.onCancel,
    required this.onActivity,
    required this.onDetails,
    this.hint,
    this.onHintTap,
    this.error,
  });

  final ValueChanged<AssignKey> onKey;
  final VoidCallback onDone;
  final VoidCallback onCancel;
  final VoidCallback onActivity;
  final VoidCallback onDetails;

  /// For example "Assign ₱14,000.00 more to reach your target".
  final String? hint;
  final VoidCallback? onHintTap;

  /// Why the typed sum cannot be saved, shown instead of [hint].
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;
    final hint = this.hint;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Spacing.lg)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.sm,
            Spacing.sm,
            Spacing.sm,
            Spacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Action(
                    icon: Icons.receipt_long_outlined,
                    label: 'Activity',
                    onTap: onActivity,
                  ),
                  _Action(
                    icon: Icons.more_horiz,
                    label: 'Details',
                    onTap: onDetails,
                  ),
                  _Action(icon: Icons.close, label: 'Cancel', onTap: onCancel),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(Spacing.sm),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                )
              else if (hint != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xs,
                    vertical: Spacing.xs,
                  ),
                  child: FilledButton.tonal(
                    onPressed: onHintTap,
                    child: Text(hint, textAlign: TextAlign.center),
                  ),
                ),
              const SizedBox(height: Spacing.xs),
              _Keys(onKey: onKey, onDone: onDone),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(Spacing.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Spacing.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                    child: Icon(icon),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(label, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Digits, the decimal point, + − =, delete and Done, four by four.
class _Keys extends StatelessWidget {
  const _Keys({required this.onKey, required this.onDone});

  final ValueChanged<AssignKey> onKey;
  final VoidCallback onDone;

  static const _rows = [
    [AssignKey.digit7, AssignKey.digit8, AssignKey.digit9, AssignKey.minus],
    [AssignKey.digit4, AssignKey.digit5, AssignKey.digit6, AssignKey.plus],
    [AssignKey.digit1, AssignKey.digit2, AssignKey.digit3, AssignKey.equals],
    [AssignKey.decimalPoint, AssignKey.digit0, AssignKey.backspace, null],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: key == null
                        ? Padding(
                            padding: const EdgeInsets.all(Spacing.xs),
                            child: FilledButton(
                              onPressed: onDone,
                              child: const Text('Done'),
                            ),
                          )
                        : _Key(assignKey: key, onTap: () => onKey(key)),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.assignKey, required this.onTap});

  final AssignKey assignKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Widget face, String label) = switch (assignKey) {
      AssignKey.backspace => (const Icon(Icons.backspace_outlined), 'Delete'),
      AssignKey.plus => (const Text('+'), 'Plus'),
      AssignKey.minus => (const Text('−'), 'Minus'),
      AssignKey.equals => (const Text('='), 'Equals'),
      AssignKey.decimalPoint => (const Text('.'), 'Decimal point'),
      _ => (Text(assignKey.character!), assignKey.character!),
    };
    final isOperator =
        assignKey.isOperator ||
        assignKey == AssignKey.equals ||
        assignKey == AssignKey.backspace;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.md),
        onTap: onTap,
        child: Center(
          child: DefaultTextStyle.merge(
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isOperator ? theme.colorScheme.primary : null,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: theme.colorScheme.primary),
              child: face,
            ),
          ),
        ),
      ),
    );
  }
}
