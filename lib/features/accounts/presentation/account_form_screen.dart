import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../data/account_repository.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/account_validation_exception.dart';
import 'account_display.dart';
import 'account_form_messages.dart';

/// Creates a new account, or edits [account] when given.
///
/// The type cannot be changed when editing. A blank opening balance means
/// zero. Closes itself after a successful save.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});

  final Account? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  static const _currencyCode = Account.defaultCurrency;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late AccountType _type;
  bool _isSaving = false;

  /// Error returned by the repository on the last save, shown on the name
  /// field until the name changes.
  String? _nameSaveError;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _type = account?.type ?? AccountType.savingsCash;
    _nameController = TextEditingController(text: account?.name ?? '');
    _amountController = TextEditingController(
      text: account == null
          ? ''
          : MoneyFormatter.formatForInput(enteredAmountFor(account)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Money _parseAmount() => _amountController.text.trim().isEmpty
      ? const Money.zero(_currencyCode)
      : MoneyParser.parse(_amountController.text, currencyCode: _currencyCode);

  String? _validateName(String? value) {
    final error = validateAccountName(value ?? '');
    return error == null ? _nameSaveError : accountNameErrorText(error);
  }

  String? _validateAmount(String? value) {
    try {
      _parseAmount();
      return null;
    } on MoneyParseException catch (exception) {
      return moneyParseErrorText(exception.error, _currencyCode);
    }
  }

  Future<void> _save() async {
    setState(() => _nameSaveError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repository = ref.read(accountRepositoryProvider);
    final account = widget.account;
    try {
      if (account == null) {
        await repository.create(
          name: _nameController.text,
          type: _type,
          enteredOpeningAmount: _parseAmount(),
        );
      } else {
        await repository.update(
          account.id,
          name: _nameController.text,
          enteredOpeningAmount: _parseAmount(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AccountValidationException catch (exception) {
      setState(
        () => _nameSaveError = accountValidationErrorText(exception.error),
      );
      _formKey.currentState!.validate();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The account could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit account' : 'New account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _AccountTypeSelector(
              selected: _type,
              enabled: !_isEditing,
              onChanged: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: Spacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. BDO Savings',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: maxAccountNameLength,
              validator: _validateName,
              onChanged: (_) => _nameSaveError = null,
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: openingBalanceLabel(_type),
                prefixText: MoneyFormatter.symbolFor(_currencyCode),
                hintText: '0.00',
                helperText: 'Leave blank for zero.',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Add account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTypeSelector extends StatelessWidget {
  const _AccountTypeSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final AccountType selected;
  final bool enabled;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AccountType>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: 'Type',
        helperText: enabled ? null : "An account's type can't be changed.",
      ),
      items: [
        for (final type in AccountType.values)
          DropdownMenuItem(value: type, child: Text(accountTypeLabel(type))),
      ],
      // A null callback disables the field.
      onChanged: enabled
          ? (type) {
              if (type != null) onChanged(type);
            }
          : null,
    );
  }
}
