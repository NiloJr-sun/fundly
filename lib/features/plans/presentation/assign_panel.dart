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
    // Docked like the phone's keyboard: edge to edge from the bottom of the
    // screen, a toolbar on top, then the keys on a flat tray.
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _ToolbarButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Activity',
                      onTap: onActivity,
                    ),
                    _ToolbarButton(
                      icon: Icons.more_horiz,
                      label: 'Details',
                      onTap: onDetails,
                    ),
                    _ToolbarButton(
                      icon: Icons.close,
                      label: 'Cancel',
                      onTap: onCancel,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    0,
                  ),
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
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.sm,
                    Spacing.sm,
                    Spacing.sm,
                    0,
                  ),
                  child: FilledButton.tonal(
                    onPressed: onHintTap,
                    child: Text(hint, textAlign: TextAlign.center),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xs,
                  Spacing.sm,
                  Spacing.xs,
                  Spacing.xs,
                ),
                child: _Keys(onKey: onKey, onDone: onDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon and label in the toolbar above the keys, like a keyboard's
/// accessory bar.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
    ),
  );
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
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      height: 46,
                      child: key == null
                          ? FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Spacing.sm,
                                  ),
                                ),
                              ),
                              onPressed: onDone,
                              child: const Text('Done'),
                            )
                          : _Key(assignKey: key, onTap: () => onKey(key)),
                    ),
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
      child: Material(
        // Key caps stand out from the tray, as on the phone's keyboard;
        // operators are tinted.
        color: isOperator
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(Spacing.sm),
        elevation: 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(Spacing.sm),
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
      ),
    );
  }
}
