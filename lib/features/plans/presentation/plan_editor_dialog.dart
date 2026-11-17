import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../../accounts/presentation/account_form_messages.dart';

/// One amount of a plan, for editing it on its own.
enum PlanAmountField { target, assigned }

/// The amounts chosen in [showPlanEditorDialog]. A `null` [target] means no
/// target; no target with nothing assigned clears the plan.
typedef PlanAmounts = ({Money? target, Money assigned});

/// Asks for [categoryName]'s target and assigned amount in one month.
/// Returns `null` if cancelled. Offers "Clear plan" only when [hasPlan].
///
/// With [only], shows just that field; the other amount is returned
/// unchanged.
Future<PlanAmounts?> showPlanEditorDialog(
  BuildContext context, {
  required String categoryName,
  required String monthLabel,
  required Money? target,
  required Money assigned,
  required bool hasPlan,
  required String currencyCode,
  PlanAmountField? only,
}) => showDialog<PlanAmounts>(
  context: context,
  builder: (_) => _PlanEditorDialog(
    categoryName: categoryName,
    monthLabel: monthLabel,
    target: target,
    assigned: assigned,
    hasPlan: hasPlan,
    currencyCode: currencyCode,
    only: only,
  ),
);

class _PlanEditorDialog extends StatefulWidget {
  const _PlanEditorDialog({
    required this.categoryName,
    required this.monthLabel,
    required this.target,
    required this.assigned,
    required this.hasPlan,
    required this.currencyCode,
    required this.only,
  });

  final String categoryName;
  final String monthLabel;
  final Money? target;
  final Money assigned;
  final bool hasPlan;
  final String currencyCode;
  final PlanAmountField? only;

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _target;
  late final TextEditingController _assigned;

  @override
  void initState() {
    super.initState();
    final target = widget.target;
    // Zero amounts start empty, showing 0.00 only as a hint, so typing
    // replaces nothing. Saving an empty field keeps the zero (see [_save]).
    _target = TextEditingController(
      text: target == null || target.isZero
          ? ''
          : MoneyFormatter.formatForInput(target),
    );
    _assigned = TextEditingController(
      text: widget.assigned.isZero
          ? ''
          : MoneyFormatter.formatForInput(widget.assigned),
    );
  }

  @override
  void dispose() {
    _target.dispose();
    _assigned.dispose();
    super.dispose();
  }

  /// Empty means "not set": no target, or nothing assigned.
  Money? _parse(TextEditingController controller) =>
      controller.text.trim().isEmpty
      ? null
      : MoneyParser.parse(controller.text, currencyCode: widget.currencyCode);

  String? _validate(TextEditingController controller) {
    try {
      _parse(controller);
      return null;
    } on MoneyParseException catch (exception) {
      return moneyParseErrorText(exception.error, widget.currencyCode);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<PlanAmounts>((
      // Empty means no target, except that a zero target left empty stays
      // zero; a zero target is a choice, not the same as none.
      target:
          _parse(_target) ??
          ((widget.target?.isZero ?? false) ? widget.target : null),
      assigned: _parse(_assigned) ?? Money.zero(widget.currencyCode),
    ));
  }

  void _clear() => Navigator.of(
    context,
  ).pop<PlanAmounts>((target: null, assigned: Money.zero(widget.currencyCode)));

  Widget _field(
    TextEditingController controller,
    String label,
    String helper, {
    bool autofocus = false,
  }) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      prefixText: MoneyFormatter.symbolFor(widget.currencyCode),
      hintText: '0.00',
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (_) => _validate(controller),
    onFieldSubmitted: (_) => _save(),
  );

  @override
  Widget build(BuildContext context) {
    final only = widget.only;
    final showTarget = only != PlanAmountField.assigned;
    final showAssigned = only != PlanAmountField.target;
    return AlertDialog(
      title: Text(widget.categoryName),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.monthLabel),
            const SizedBox(height: Spacing.sm),
            if (showTarget)
              _field(
                _target,
                'Target',
                (widget.target?.isZero ?? false)
                    ? 'Leave empty to keep a '
                          '${MoneyFormatter.format(widget.target!)} target'
                    : 'Leave empty for no target',
                autofocus: !showAssigned,
              ),
            if (showTarget && showAssigned) const SizedBox(height: Spacing.sm),
            if (showAssigned)
              _field(
                _assigned,
                'Assigned',
                'Money set aside so far this month',
                autofocus: true,
              ),
          ],
        ),
      ),
      actions: [
        if (widget.hasPlan && only == null)
          TextButton(onPressed: _clear, child: const Text('Clear plan')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
