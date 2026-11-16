import 'package:flutter/material.dart';

import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../../accounts/presentation/account_form_messages.dart';

/// What the user chose in [showPlannedAmountDialog].
sealed class PlannedAmountChoice {
  const PlannedAmountChoice();
}

/// Save [amount] as the plan (zero allowed).
final class SetPlannedAmount extends PlannedAmountChoice {
  const SetPlannedAmount(this.amount);

  final Money amount;
}

/// Remove the plan, leaving the category unplanned.
final class ClearPlannedAmount extends PlannedAmountChoice {
  const ClearPlannedAmount();
}

/// Asks for a planned amount for [categoryName]. Returns `null` if cancelled.
/// Offers "Clear plan" only when [current] is set.
Future<PlannedAmountChoice?> showPlannedAmountDialog(
  BuildContext context, {
  required String categoryName,
  required String monthLabel,
  required Money? current,
  required String currencyCode,
}) => showDialog<PlannedAmountChoice>(
  context: context,
  builder: (_) => _PlannedAmountDialog(
    categoryName: categoryName,
    monthLabel: monthLabel,
    current: current,
    currencyCode: currencyCode,
  ),
);

class _PlannedAmountDialog extends StatefulWidget {
  const _PlannedAmountDialog({
    required this.categoryName,
    required this.monthLabel,
    required this.current,
    required this.currencyCode,
  });

  final String categoryName;
  final String monthLabel;
  final Money? current;
  final String currencyCode;

  @override
  State<_PlannedAmountDialog> createState() => _PlannedAmountDialogState();
}

class _PlannedAmountDialogState extends State<_PlannedAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _controller = TextEditingController(
      text: current == null ? '' : MoneyFormatter.formatForInput(current),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Money _parse() =>
      MoneyParser.parse(_controller.text, currencyCode: widget.currencyCode);

  String? _validate(String? _) {
    try {
      _parse();
      return null;
    } on MoneyParseException catch (exception) {
      return moneyParseErrorText(exception.error, widget.currencyCode);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(SetPlannedAmount(_parse()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.categoryName),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Planned for ${widget.monthLabel}',
            prefixText: MoneyFormatter.symbolFor(widget.currencyCode),
            hintText: '0.00',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validate,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const ClearPlannedAmount()),
            child: const Text('Clear plan'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
