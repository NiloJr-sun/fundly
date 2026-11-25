import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../data/custom_bank_repository.dart';
import '../domain/account_rules.dart';
import '../domain/custom_bank.dart';
import 'account_form_messages.dart';
import 'bank_display.dart';

/// Asks for a new custom bank's name, saves it and returns it. Returns
/// `null` if cancelled (docs/BANKS_PLAN.md, B-5, B-8).
Future<CustomBank?> showNewBankDialog(BuildContext context) =>
    showDialog<CustomBank>(
      context: context,
      builder: (_) => const _BankDialog(existing: null, accountCount: 0),
    );

/// Renames [bank], or deletes it while no account uses it ([accountCount]
/// is zero).
Future<void> showEditBankDialog(
  BuildContext context, {
  required CustomBank bank,
  required int accountCount,
}) => showDialog<void>(
  context: context,
  builder: (_) => _BankDialog(existing: bank, accountCount: accountCount),
);

class _BankDialog extends ConsumerStatefulWidget {
  const _BankDialog({required this.existing, required this.accountCount});

  /// `null` when adding a bank.
  final CustomBank? existing;

  /// Accounts, active or archived, belonging to [existing].
  final int accountCount;

  @override
  ConsumerState<_BankDialog> createState() => _BankDialogState();
}

class _BankDialogState extends ConsumerState<_BankDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  /// Error returned by the repository on the last save, shown on the name
  /// field until the name changes.
  String? _nameSaveError;

  /// Error that is not about the name, e.g. the bank came into use.
  String? _saveError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
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
    final repository = ref.read(customBankRepositoryProvider);
    final existing = widget.existing;
    try {
      final saved = existing == null
          ? await repository.create(_nameController.text)
          : await repository.rename(existing.id, _nameController.text);
      if (mounted) Navigator.of(context).pop(saved);
    } on CustomBankValidationException catch (exception) {
      setState(() => _nameSaveError = customBankErrorText(exception.error));
      _formKey.currentState!.validate();
    } on Object {
      setState(() => _saveError = 'This bank could not be saved.');
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
        content: const Text('No account belongs to this bank.'),
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
      await ref.read(customBankRepositoryProvider).delete(existing.id);
      if (mounted) Navigator.of(context).pop();
    } on CustomBankValidationException catch (exception) {
      setState(() => _saveError = customBankErrorText(exception.error));
    } on Object {
      setState(() => _saveError = 'This bank could not be deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;
    final saveError = _saveError;
    final usage = switch (widget.accountCount) {
      0 => null,
      1 => "1 account belongs to this bank, so it can't be deleted.",
      final count =>
        "$count accounts belong to this bank, so it can't be "
            'deleted.',
    };
    return AlertDialog(
      title: Text(_isEditing ? 'Edit bank' : 'New bank'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (existing != null) ...[
                Center(child: BankAvatar(badge: customBankBadge(existing))),
                const SizedBox(height: Spacing.md),
              ],
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Town Cooperative',
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: maxAccountNameLength,
                validator: _validateName,
                onChanged: (_) => _nameSaveError = null,
              ),
              if (usage != null) Text(usage, style: theme.textTheme.bodySmall),
              if (saveError != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  saveError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing && widget.accountCount == 0)
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
          child: Text(_isEditing ? 'Save' : 'Add bank'),
        ),
      ],
    );
  }
}
