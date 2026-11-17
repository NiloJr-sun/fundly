import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../data/custom_account_type_repository.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/custom_account_type.dart';
import '../domain/custom_account_type_validation_exception.dart';
import 'account_display.dart';
import 'account_form_messages.dart';

/// Asks for a new custom account type's name and class, saves it, and returns
/// it. Returns `null` if cancelled.
///
/// An Asset type works like Savings / Cash. A Liability type works like a
/// credit card or a loan, chosen here; the choice cannot change later.
Future<CustomAccountType?> showNewAccountTypeDialog(BuildContext context) =>
    showDialog<CustomAccountType>(
      context: context,
      builder: (_) => const _NewAccountTypeDialog(),
    );

class _NewAccountTypeDialog extends ConsumerStatefulWidget {
  const _NewAccountTypeDialog();

  @override
  ConsumerState<_NewAccountTypeDialog> createState() =>
      _NewAccountTypeDialogState();
}

class _NewAccountTypeDialogState extends ConsumerState<_NewAccountTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AccountClass _class = AccountClass.asset;
  AccountType _liabilityType = AccountType.credit;
  bool _isSaving = false;

  /// Error returned by the repository on the last save, shown on the name
  /// field until the name changes.
  String? _nameSaveError;

  AccountType get _baseType => switch (_class) {
    AccountClass.asset => AccountType.savingsCash,
    AccountClass.liability => _liabilityType,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final error = validateAccountName(value ?? '');
    return error == null ? _nameSaveError : accountNameErrorText(error);
  }

  Future<void> _save() async {
    setState(() => _nameSaveError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final created = await ref
          .read(customAccountTypeRepositoryProvider)
          .create(name: _nameController.text, baseType: _baseType);
      if (mounted) Navigator.of(context).pop(created);
    } on CustomAccountTypeValidationException catch (exception) {
      setState(
        () => _nameSaveError = customAccountTypeErrorText(exception.error),
      );
      _formKey.currentState!.validate();
    } on Object {
      setState(() => _nameSaveError = 'This type could not be saved.');
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('New account type'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. E-wallet',
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: maxAccountNameLength,
                validator: _validateName,
                onChanged: (_) => _nameSaveError = null,
              ),
              const SizedBox(height: Spacing.sm),
              Text('Class', style: textTheme.labelLarge),
              const SizedBox(height: Spacing.xs),
              SegmentedButton<AccountClass>(
                segments: [
                  for (final accountClass in AccountClass.values)
                    ButtonSegment(
                      value: accountClass,
                      label: Text(switch (accountClass) {
                        AccountClass.asset => 'Asset',
                        AccountClass.liability => 'Liability',
                      }),
                    ),
                ],
                selected: {_class},
                onSelectionChanged: (selection) =>
                    setState(() => _class = selection.single),
              ),
              if (_class == AccountClass.liability) ...[
                const SizedBox(height: Spacing.md),
                Text('Works like', style: textTheme.labelLarge),
                const SizedBox(height: Spacing.xs),
                SegmentedButton<AccountType>(
                  segments: const [
                    ButtonSegment(
                      value: AccountType.credit,
                      label: Text('Credit card'),
                    ),
                    ButtonSegment(value: AccountType.loan, label: Text('Loan')),
                  ],
                  selected: {_liabilityType},
                  onSelectionChanged: (selection) =>
                      setState(() => _liabilityType = selection.single),
                ),
              ],
              const SizedBox(height: Spacing.sm),
              Text(
                "${accountTypeDescription(_baseType)} This can't be changed "
                'later.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Add type'),
        ),
      ],
    );
  }
}
