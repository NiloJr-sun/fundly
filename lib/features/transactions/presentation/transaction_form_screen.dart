import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../accounts/presentation/account_display.dart';
import '../../accounts/presentation/account_form_messages.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_rules.dart';
import '../domain/transaction_type.dart';
import '../domain/transaction_validation_exception.dart';
import 'transaction_display.dart';

/// Adds a transaction of [type]. Closes itself after a successful save.
///
/// Field errors come from [validateTransaction], the same rules the
/// repository enforces, so the form and the data layer cannot disagree.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, required this.type, this.clock});

  final TransactionType type;

  /// Supplies "today" for the default date. Defaults to the system clock.
  final DateTime Function()? clock;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  static const _currencyCode = Account.defaultCurrency;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _noteController = TextEditingController();
  late CalendarDate _date;
  int? _sourceAccountId;
  int? _destinationAccountId;
  int? _categoryId;
  bool _isSaving = false;

  /// Errors from the last save attempt, shown under their fields.
  Map<TransactionField, String> _errors = const {};

  TransactionType get _type => widget.type;

  CategoryKind? get _categoryKind => switch (_type) {
    TransactionType.spending => CategoryKind.spending,
    TransactionType.inflow => CategoryKind.inflow,
    TransactionType.transfer || TransactionType.creditCardPayment => null,
  };

  @override
  void initState() {
    super.initState();
    _date = CalendarDate.today(clock: widget.clock);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _errorFor(TransactionField field) => _errors[field];

  /// Builds a draft from the inputs. [amount] is `null` if it did not parse.
  TransactionDraft _draft(Money? amount) => TransactionDraft(
    type: _type,
    // A placeholder keeps the other checks running when the amount is
    // invalid; the amount's own error is reported separately.
    amount: amount ?? const Money(minorUnits: 1, currencyCode: _currencyCode),
    date: _date,
    payee: _payeeController.text,
    categoryId: _categoryId,
    sourceAccountId: _type.hasSourceAccount ? _sourceAccountId : null,
    destinationAccountId: _type.hasDestinationAccount
        ? _destinationAccountId
        : null,
    note: _noteController.text,
  );

  Map<TransactionField, String> _displayErrors(
    Iterable<TransactionValidationError> errors,
  ) {
    final result = <TransactionField, String>{};
    for (final error in errors) {
      final display = transactionErrorDisplay(error, _type);
      result.putIfAbsent(display.field, () => display.message);
    }
    return result;
  }

  Future<void> _save(List<Account> accounts, List<Category> categories) async {
    Money? amount;
    String? amountError;
    try {
      amount = MoneyParser.parse(
        _amountController.text,
        currencyCode: _currencyCode,
      );
    } on MoneyParseException catch (exception) {
      amountError = moneyParseErrorText(exception.error, _currencyCode);
    }

    final draft = _draft(amount);
    final errors = _displayErrors(
      validateTransaction(
        draft,
        accounts: {for (final account in accounts) account.id: account},
        categories: {for (final category in categories) category.id: category},
      ),
    );
    if (amountError != null) errors[TransactionField.amount] = amountError;
    if (!_showErrors(errors)) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(transactionRepositoryProvider).create(draft);
      messenger.showSnackBar(
        SnackBar(content: Text('${transactionTypeLabel(_type)} saved')),
      );
      navigator.pop();
    } on TransactionValidationException catch (exception) {
      // The data layer re-checks; show anything it found that we did not.
      _showErrors(_displayErrors(exception.errors));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('The transaction could not be saved.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Shows [errors] and returns whether the form is valid.
  bool _showErrors(Map<TransactionField, String> errors) {
    setState(() => _errors = errors);
    _formKey.currentState!.validate();
    final general = errors[TransactionField.form];
    if (general != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(general)));
    }
    return errors.isEmpty;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = CalendarDate.fromDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(activeAccountsProvider);
    final kind = _categoryKind;
    final categories = kind == null
        ? const AsyncData<List<Category>>([])
        : ref.watch(categoriesByKindProvider(kind));

    return Scaffold(
      appBar: AppBar(title: Text('New ${transactionTypeLabel(_type)}')),
      body: switch ((accounts, categories)) {
        (AsyncData(value: final a), AsyncData(value: final c)) => _buildForm(
          a,
          c,
        ),
        (AsyncError(), _) || (_, AsyncError()) => const CenteredMessage(
          'Your accounts or categories could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildForm(List<Account> accounts, List<Category> categories) {
    final sources = _usable(accounts, allowedSourceAccountTypes(_type));
    final destinations = _usable(
      accounts,
      allowedDestinationAccountTypes(_type),
    );
    final missing = _missingAccountsMessage(sources, destinations);
    if (missing != null) return CenteredMessage(missing);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: MoneyFormatter.symbolFor(_currencyCode),
              hintText: '0.00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (_) => _errorFor(TransactionField.amount),
          ),
          const SizedBox(height: Spacing.md),
          _DateField(date: _date, onTap: _pickDate),
          if (_type.hasSourceAccount) ...[
            const SizedBox(height: Spacing.md),
            _AccountField(
              label: sourceAccountLabel(_type),
              accounts: sources,
              value: _sourceAccountId,
              onChanged: (id) => setState(() => _sourceAccountId = id),
              validator: (_) => _errorFor(TransactionField.sourceAccount),
            ),
          ],
          if (_type.hasDestinationAccount) ...[
            const SizedBox(height: Spacing.md),
            _AccountField(
              label: destinationAccountLabel(_type),
              accounts: destinations,
              value: _destinationAccountId,
              onChanged: (id) => setState(() => _destinationAccountId = id),
              validator: (_) => _errorFor(TransactionField.destinationAccount),
            ),
          ],
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _payeeController,
            decoration: InputDecoration(labelText: payeeLabel(_type)),
            textCapitalization: TextCapitalization.words,
            maxLength: maxPayeeLength,
            validator: (_) => _errorFor(TransactionField.payee),
          ),
          if (_categoryKind != null)
            _CategoryField(
              categories: categories,
              optional: _type == TransactionType.inflow,
              value: _categoryId,
              onChanged: (id) => setState(() => _categoryId = id),
              validator: (_) => _errorFor(TransactionField.category),
            ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 3,
            minLines: 1,
            maxLength: maxNoteLength,
            validator: (_) => _errorFor(TransactionField.note),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _isSaving ? null : () => _save(accounts, categories),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static List<Account> _usable(
    List<Account> accounts,
    Set<AccountType> types,
  ) => accounts.where((account) => types.contains(account.type)).toList();

  /// Explains what to add first when a required account list is empty.
  String? _missingAccountsMessage(
    List<Account> sources,
    List<Account> destinations,
  ) {
    String need(Set<AccountType> types) =>
        types.map(accountTypeLabel).join(' or ');
    if (_type.hasSourceAccount && sources.isEmpty) {
      return 'Add a ${need(allowedSourceAccountTypes(_type))} account first.';
    }
    if (_type.hasDestinationAccount && destinations.isEmpty) {
      return 'Add a ${need(allowedDestinationAccountTypes(_type))} account '
          'first.';
    }
    return null;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final CalendarDate date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormatter.localDate(date.toLocalDateTime())),
      ),
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final List<Account> accounts;
  final int? value;
  final ValueChanged<int?> onChanged;
  final FormFieldValidator<int> validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      // Lets long account names shrink with an ellipsis instead of
      // overflowing on narrow phones.
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Text(
              '${account.name} · ${accountTypeLabel(account.type)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.categories,
    required this.optional,
    required this.value,
    required this.onChanged,
    required this.validator,
  });

  final List<Category> categories;
  final bool optional;
  final int? value;
  final ValueChanged<int?> onChanged;
  final FormFieldValidator<int> validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: optional ? 'Category (optional)' : 'Category',
      ),
      items: [
        if (optional) const DropdownMenuItem<int>(child: Text('None')),
        for (final category in categories)
          DropdownMenuItem(value: category.id, child: Text(category.name)),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}
