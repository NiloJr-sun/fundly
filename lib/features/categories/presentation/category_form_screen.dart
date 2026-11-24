import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_form_messages.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';
import '../domain/category_rules.dart';
import '../domain/category_validation_exception.dart';
import 'categories_providers.dart';
import 'category_display.dart';

/// Creates a category, or edits [category] when given: rename, change the
/// Plans group and default Target of a spending category, archive or
/// unarchive, and delete when no transaction uses it.
///
/// The kind cannot be changed when editing. Closes itself after a successful
/// save, archive or delete.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late CategoryKind _kind;
  late PlanGroup _planGroup;
  bool _isBusy = false;

  /// Error returned by the repository on the last save, shown on the name
  /// field until the name changes.
  String? _nameSaveError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _kind = widget.category?.kind ?? CategoryKind.spending;
    _planGroup = widget.category?.planGroup ?? PlanGroup.spending;
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    final target = widget.category?.defaultTarget;
    // A zero Target starts empty, showing 0.00 only as a hint; saving the
    // empty field keeps the zero (see [_defaultTarget]).
    _targetController = TextEditingController(
      text: target == null || target.isZero
          ? ''
          : MoneyFormatter.formatForInput(target),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  /// The entered default Target: empty means none, except that a zero
  /// Target left empty stays zero, as in the Plans editor.
  Money? _defaultTarget() {
    final text = _targetController.text;
    if (text.trim().isNotEmpty) {
      return MoneyParser.parse(text, currencyCode: Account.defaultCurrency);
    }
    final existing = widget.category?.defaultTarget;
    return (existing?.isZero ?? false) ? existing : null;
  }

  String? _validateTarget(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    try {
      MoneyParser.parse(value!, currencyCode: Account.defaultCurrency);
      return null;
    } on MoneyParseException catch (exception) {
      return moneyParseErrorText(exception.error, Account.defaultCurrency);
    }
  }

  String? _validateName(String? value) {
    final error = validateCategoryName(value ?? '');
    return error == null ? _nameSaveError : categoryNameErrorText(error);
  }

  /// Runs [action], then closes the screen with [doneMessage]. Shows
  /// repository errors on the name field or in a snack bar.
  Future<void> _run(
    Future<void> Function(CategoryRepository repository) action, {
    required String doneMessage,
    required String failureMessage,
  }) async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action(ref.read(categoryRepositoryProvider));
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
      navigator.pop();
    } on CategoryValidationException catch (exception) {
      final message = categoryValidationErrorText(exception.error);
      if (exception.error == CategoryValidationError.inUse) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      } else {
        setState(() => _nameSaveError = message);
        _formKey.currentState!.validate();
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _nameSaveError = null);
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text;
    final category = widget.category;
    // Only spending categories have a group and a default Target; inflow
    // keeps the defaults.
    final isSpending = _kind == CategoryKind.spending;
    final planGroup = isSpending ? _planGroup : PlanGroup.spending;
    final defaultTarget = isSpending ? _defaultTarget() : null;
    await _run(
      (repository) async {
        if (category == null) {
          await repository.create(
            name: name,
            kind: _kind,
            planGroup: planGroup,
            defaultTarget: defaultTarget,
          );
          return;
        }
        await repository.rename(category.id, name);
        if (planGroup != category.planGroup) {
          await repository.setPlanGroup(category.id, planGroup);
        }
        if (defaultTarget != category.defaultTarget) {
          await repository.setDefaultTarget(category.id, defaultTarget);
        }
      },
      doneMessage: category == null ? 'Category added' : 'Changes saved',
      failureMessage: 'The category could not be saved.',
    );
  }

  Future<void> _setArchived(Category category, {required bool archived}) =>
      _run(
        (repository) => repository.setArchived(category.id, archived: archived),
        doneMessage: archived
            ? '${category.name} archived'
            : '${category.name} restored',
        failureMessage: 'The category could not be changed.',
      );

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      (repository) => repository.delete(category.id),
      doneMessage: '${category.name} deleted',
      failureMessage: 'The category could not be deleted.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit category' : 'New category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _KindSelector(
              selected: _kind,
              enabled: !_isEditing,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
            if (_kind == CategoryKind.spending) ...[
              const SizedBox(height: Spacing.lg),
              _GroupSelector(
                selected: _planGroup,
                onChanged: (group) => setState(() => _planGroup = group),
              ),
              const SizedBox(height: Spacing.lg),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target',
                  helperText: (category?.defaultTarget?.isZero ?? false)
                      ? 'Default for each new month. Leave empty to keep a '
                            '${MoneyFormatter.format(category!.defaultTarget!)}'
                            ' target.'
                      : 'Default for each new month. Leave empty for no '
                            'target.',
                  helperMaxLines: 2,
                  prefixText: MoneyFormatter.symbolFor(Account.defaultCurrency),
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateTarget,
              ),
            ],
            const SizedBox(height: Spacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Groceries',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: maxCategoryNameLength,
              validator: _validateName,
              onChanged: (_) => _nameSaveError = null,
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: _isBusy ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Add category'),
            ),
            if (category != null) ...[
              const SizedBox(height: Spacing.md),
              OutlinedButton.icon(
                onPressed: _isBusy
                    ? null
                    : () => _setArchived(
                        category,
                        archived: !category.isArchived,
                      ),
                icon: Icon(
                  category.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                label: Text(
                  category.isArchived
                      ? 'Unarchive category'
                      : 'Archive category',
                ),
              ),
              _DeleteButton(
                category: category,
                enabled: !_isBusy,
                onPressed: () => _delete(category),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Deletes an unused category. A used one shows why it can only be archived.
class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({
    required this.category,
    required this.enabled,
    required this.onPressed,
  });

  final Category category;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inUse = ref.watch(usedCategoryIdsProvider).contains(category.id);
    if (inUse) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.md),
        child: Text(
          'Used by transactions, so it can be archived but not deleted.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Delete category'),
      ),
    );
  }
}

/// Which section of the Plans page a spending category is listed under.
class _GroupSelector extends StatelessWidget {
  const _GroupSelector({required this.selected, required this.onChanged});

  final PlanGroup selected;
  final ValueChanged<PlanGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PlanGroup>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Group',
        helperText: 'The section it appears in on the Plans page.',
      ),
      items: [
        for (final group in PlanGroup.values)
          DropdownMenuItem(value: group, child: Text(planGroupLabel(group))),
      ],
      onChanged: (group) {
        if (group != null) onChanged(group);
      },
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final CategoryKind selected;
  final bool enabled;
  final ValueChanged<CategoryKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CategoryKind>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: 'Kind',
        helperText: enabled ? null : "A category's kind can't be changed.",
      ),
      items: [
        for (final kind in CategoryKind.values)
          DropdownMenuItem(value: kind, child: Text(categoryKindLabel(kind))),
      ],
      // A null callback disables the field.
      onChanged: enabled
          ? (kind) {
              if (kind != null) onChanged(kind);
            }
          : null,
    );
  }
}
