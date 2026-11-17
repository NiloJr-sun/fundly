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
/// credit card or a loan.
Future<CustomAccountType?> showNewAccountTypeDialog(BuildContext context) =>
    showDialog<CustomAccountType>(
      context: context,
      builder: (_) => const _AccountTypeDialog(existing: null, accountCount: 0),
    );

/// Edits [type]: rename it, change its class while no account uses it
/// ([accountCount] is zero), or delete it when unused.
Future<void> showEditAccountTypeDialog(
  BuildContext context, {
  required CustomAccountType type,
  required int accountCount,
}) => showDialog<void>(
  context: context,
  builder: (_) =>
      _AccountTypeDialog(existing: type, accountCount: accountCount),
);

class _AccountTypeDialog extends ConsumerStatefulWidget {
  const _AccountTypeDialog({
    required this.existing,
    required this.accountCount,
  });

  /// `null` when adding a type.
  final CustomAccountType? existing;

  /// Accounts, active or archived, using [existing].
  final int accountCount;

  @override
  ConsumerState<_AccountTypeDialog> createState() => _AccountTypeDialogState();
}

class _AccountTypeDialogState extends ConsumerState<_AccountTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late AccountClass _class;
  late AccountType _liabilityType;
  bool _isSaving = false;

  /// Error returned by the repository on the last save, shown on the name
  /// field until the name changes.
  String? _nameSaveError;

  /// Error that is not about the name, e.g. the type came into use meanwhile.
  String? _saveError;

  bool get _isEditing => widget.existing != null;

  /// The class can change only while no account uses the type.
  bool get _classLocked => widget.accountCount > 0;

  AccountType get _baseType => switch (_class) {
    AccountClass.asset => AccountType.savingsCash,
    AccountClass.liability => _liabilityType,
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    final baseType = existing?.baseType ?? AccountType.savingsCash;
    _class = baseType.accountClass;
    _liabilityType = baseType.isLiability ? baseType : AccountType.credit;
  }

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
    setState(() {
      _nameSaveError = null;
      _saveError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repository = ref.read(customAccountTypeRepositoryProvider);
    final existing = widget.existing;
    try {
      final saved = existing == null
          ? await repository.create(
              name: _nameController.text,
              baseType: _baseType,
            )
          : await repository.update(
              existing.id,
              name: _nameController.text,
              baseType: _classLocked ? null : _baseType,
            );
      if (mounted) Navigator.of(context).pop(saved);
    } on CustomAccountTypeValidationException catch (exception) {
      final message = customAccountTypeErrorText(exception.error);
      setState(() {
        if (exception.error == CustomAccountTypeValidationError.baseTypeInUse) {
          _saveError = message;
        } else {
          _nameSaveError = message;
        }
      });
      _formKey.currentState!.validate();
    } on Object {
      setState(() => _saveError = 'This type could not be saved.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${existing.name}?'),
        content: const Text('No account uses this type.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(customAccountTypeRepositoryProvider).delete(existing.id);
      if (mounted) Navigator.of(context).pop();
    } on CustomAccountTypeValidationException catch (exception) {
      setState(() => _saveError = customAccountTypeErrorText(exception.error));
    } on Object {
      setState(() => _saveError = 'This type could not be deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final classChange = _classLocked
        ? null
        : (Set<AccountClass> selection) =>
              setState(() => _class = selection.single);
    final liabilityChange = _classLocked
        ? null
        : (Set<AccountType> selection) =>
              setState(() => _liabilityType = selection.single);
    final accounts = widget.accountCount == 1
        ? '1 account uses'
        : '${widget.accountCount} accounts use';
    final saveError = _saveError;
    return AlertDialog(
      title: Text(_isEditing ? 'Edit account type' : 'New account type'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
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
                onSelectionChanged: classChange,
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
                  onSelectionChanged: liabilityChange,
                ),
              ],
              const SizedBox(height: Spacing.sm),
              Text(
                _classLocked
                    ? '${accountTypeDescription(_baseType)} $accounts this '
                          "type, so its class can't change."
                    : '${accountTypeDescription(_baseType)} This can change '
                          'only while no account uses the type.',
                style: textTheme.bodySmall,
              ),
              if (saveError != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  saveError,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing && !_classLocked)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isEditing ? 'Save' : 'Add type'),
        ),
      ],
    );
  }
}
