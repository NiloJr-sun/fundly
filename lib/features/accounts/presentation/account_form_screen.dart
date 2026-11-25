import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../../transactions/presentation/account_picker_field.dart';
import '../data/account_repository.dart';
import '../data/card_funding.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/account_validation_exception.dart';
import '../domain/custom_account_type.dart';
import '../domain/custom_bank.dart';
import 'account_display.dart';
import 'account_form_messages.dart';
import 'account_type_dialog.dart';
import 'accounts_providers.dart';
import 'bank_display.dart';
import 'bank_picker.dart';

/// A choice in the account type dropdown: a built-in [type], or the custom
/// type [customTypeId] based on it.
typedef AccountTypeChoice = ({AccountType type, String? customTypeId});

/// Creates a new account, or edits [account] when given.
///
/// When editing, the type can only change to another type with the same
/// built-in base (e.g. Savings / Cash to a custom "E-wallet"). A blank
/// opening balance means zero. Closes itself after a successful save.
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
  late AccountTypeChoice _choice;
  late bool _isBudgetAccount;
  bool _isSaving = false;

  /// "This is a credit card" is ticked: the starting money comes from the
  /// card [_cardId] as a Transfer, not as an opening balance. Form state
  /// only; nothing about it is stored on the account.
  bool _isCreditCard = false;
  String? _cardId;

  /// The chosen bank; both fields `null` means No bank (docs/BANKS_PLAN.md,
  /// B-4). When editing, it starts as the account's bank, even a built-in
  /// key this app does not know, which is kept unless the user picks another.
  late AccountBank _bank;

  /// A bank added from the picker, shown until the custom banks list
  /// includes it.
  CustomBank? _addedBank;

  /// A type created from the dropdown, shown until the custom types list
  /// includes it.
  CustomAccountType? _createdType;

  /// Bumped to rebuild the type dropdown when its selection is reset, e.g.
  /// after "New account type" is cancelled.
  int _selectorGeneration = 0;

  AccountType get _type => _choice.type;

  /// Only an active Savings/Cash account (custom asset types included) can
  /// be the budget account.
  bool get _canBeBudgetAccount =>
      _type == AccountType.savingsCash &&
      !(widget.account?.isArchived ?? false);

  /// Only an active asset account can take its starting money from a card
  /// (a cash advance goes only to Savings/Cash).
  bool get _canTakeFromCard =>
      _type == AccountType.savingsCash &&
      !(widget.account?.isArchived ?? false);

  bool get _takesFromCard => _isCreditCard && _canTakeFromCard;

  /// Error returned by the repository on the last save, shown on the name
  /// field until the name changes.
  String? _nameSaveError;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _isBudgetAccount = account?.isBudgetAccount ?? false;
    _bank = account?.bank ?? (bankKey: null, customBankId: null);
    _choice = (
      type: account?.type ?? AccountType.savingsCash,
      customTypeId: account?.customTypeId,
    );
    _nameController = TextEditingController(text: account?.name ?? '');
    // A zero opening balance starts empty, showing 0.00 only as a hint;
    // an empty field saves as zero.
    final opening = account == null ? null : enteredAmountFor(account);
    _amountController = TextEditingController(
      text: opening == null || opening.isZero
          ? ''
          : MoneyFormatter.formatForInput(opening),
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
      final amount = _parseAmount();
      if (_takesFromCard && amount.isZero) {
        return 'Enter the amount to take from the card.';
      }
      return null;
    } on MoneyParseException catch (exception) {
      return moneyParseErrorText(exception.error, _currencyCode);
    }
  }

  Future<void> _save() async {
    setState(() => _nameSaveError = null);
    if (!_formKey.currentState!.validate()) return;

    final account = widget.account;
    final wantsBudget = _isBudgetAccount && _canBeBudgetAccount;
    final wasBudget = account?.isBudgetAccount ?? false;

    setState(() => _isSaving = true);
    final repository = ref.read(accountRepositoryProvider);
    try {
      final saved = _takesFromCard
          ? await _saveFromCard(account)
          : account == null
          ? await repository.create(
              name: _nameController.text,
              type: _type,
              enteredOpeningAmount: _parseAmount(),
              customTypeId: _choice.customTypeId,
              bankKey: _bank.bankKey,
              customBankId: _bank.customBankId,
            )
          : await repository.update(
              account.id,
              name: _nameController.text,
              enteredOpeningAmount: _parseAmount(),
              customType: (id: _choice.customTypeId),
              // Unchanged: keep the stored bank as it is.
              bank: _bank == account.bank ? null : _bank,
            );
      if (wantsBudget && !wasBudget) {
        await repository.setBudgetAccount(saved.id);
      } else if (!wantsBudget && wasBudget) {
        await repository.clearBudgetAccount(saved.id);
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

  /// Saves the account with its starting money taken from the chosen card.
  Future<Account> _saveFromCard(Account? account) {
    final funding = ref.read(cardFundingProvider);
    final cardId = _cardId!;
    return account == null
        ? funding.create(
            name: _nameController.text,
            type: _type,
            amount: _parseAmount(),
            cardId: cardId,
            customTypeId: _choice.customTypeId,
            bankKey: _bank.bankKey,
            customBankId: _bank.customBankId,
          )
        : funding.update(
            account.id,
            name: _nameController.text,
            amount: _parseAmount(),
            cardId: cardId,
            customType: (id: _choice.customTypeId),
            bank: _bank == account.bank ? null : _bank,
          );
  }

  Future<void> _addType() async {
    final created = await showNewAccountTypeDialog(context);
    if (!mounted) return;
    setState(() {
      _selectorGeneration++;
      if (created != null) {
        _createdType = created;
        _choice = (type: created.baseType, customTypeId: created.id);
      }
    });
  }

  Future<void> _pickBank() async {
    final pick = await showBankPicker(context, selected: _bank);
    if (pick == null || !mounted) return;
    setState(() {
      _bank = pick.bank;
      if (pick.added case final added?) _addedBank = added;
    });
  }

  /// The chosen bank's badge, or `null` for No bank.
  BankBadge? _bankBadge() {
    final banks = ref.watch(customBanksByIdProvider);
    final added = _addedBank;
    return bankBadgeFor(
      _bank,
      added == null || banks.containsKey(added.id)
          ? banks
          : {...banks, added.id: added},
    );
  }

  /// Custom types to offer, including one just created that the stream has
  /// not delivered yet. `null` while loading.
  List<CustomAccountType>? _customTypes() {
    final loaded = ref.watch(customAccountTypesProvider);
    final types = loaded.value ?? (loaded.hasError ? const [] : null);
    final created = _createdType;
    if (types == null || created == null) return types;
    if (types.any((type) => type.id == created.id)) return types;
    return [...types, created];
  }

  /// The "Starting money from" field, listing active credit accounts
  /// (custom credit types included).
  Widget _cardPicker() {
    final loaded = ref.watch(activeAccountsProvider);
    final accounts = loaded.value;
    if (accounts == null) {
      return loaded.hasError
          ? const Text('Your credit cards could not be loaded.')
          : const LinearProgressIndicator();
    }
    final cards = [
      for (final account in accounts)
        if (account.type == AccountType.credit) account,
    ];
    if (cards.isEmpty) {
      return const Text('Add a credit card account first.');
    }
    return AccountPickerField(
      label: 'Starting money from',
      accounts: cards,
      value: _cardId,
      onChanged: (id) => setState(() => _cardId = id),
      validator: (id) => id == null ? 'Choose a credit card.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final customTypes = _customTypes();
    final bankBadge = _bankBadge();
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit account' : 'New account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            if (customTypes == null)
              const LinearProgressIndicator()
            else
              _AccountTypeSelector(
                key: ValueKey(_selectorGeneration),
                selected: _choice,
                customTypes: customTypes,
                isEditing: _isEditing,
                onChanged: (choice) => setState(() => _choice = choice),
                onAddType: _addType,
              ),
            const SizedBox(height: Spacing.lg),
            _BankField(
              badge: bankBadge,
              fallbackIcon: accountTypeIcon(_type),
              onTap: _pickBank,
            ),
            const SizedBox(height: Spacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. ${bankBadge?.name ?? 'BDO'} Savings',
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
                labelText: _takesFromCard
                    ? 'Starting money'
                    : openingBalanceLabel(_type),
                prefixText: MoneyFormatter.symbolFor(_currencyCode),
                hintText: '0.00',
                helperText: _takesFromCard
                    ? 'Taken from the card as a Transfer dated today. '
                          'The opening balance becomes zero.'
                    : 'Leave blank for zero.',
                helperMaxLines: 2,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validateAmount,
            ),
            if (_canTakeFromCard) ...[
              const SizedBox(height: Spacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('This is a credit card'),
                subtitle: const Text(
                  'Take its starting money from one of your credit cards.',
                ),
                value: _isCreditCard,
                onChanged: (value) =>
                    setState(() => _isCreditCard = value ?? false),
              ),
              if (_isCreditCard) _cardPicker(),
            ],
            if (_canBeBudgetAccount) ...[
              const SizedBox(height: Spacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use as budget account'),
                subtitle: const Text(
                  'Money coming into it funds Ready to assign on Plans. '
                  'Transfers between budget accounts are not counted.',
                ),
                value: _isBudgetAccount,
                onChanged: (value) => setState(() => _isBudgetAccount = value),
              ),
            ],
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

/// The Bank field: the chosen bank's logo and name, or No bank. Tap to
/// open the bank picker.
class _BankField extends StatelessWidget {
  const _BankField({
    required this.badge,
    required this.fallbackIcon,
    required this.onTap,
  });

  final BankBadge? badge;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Bank',
            helperText: 'Optional. Its logo shows beside the account.',
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          child: Row(
            children: [
              BankAvatar(badge: badge, fallbackIcon: fallbackIcon, size: 28),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  badge?.name ?? 'No bank',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dropdown value of "New account type…".
const Object _newTypeItem = #newAccountType;

/// The type dropdown: built-in and custom types under Assets and
/// Liabilities headings, then "New account type" when creating.
///
/// When editing, only types with the same built-in base are offered.
class _AccountTypeSelector extends StatelessWidget {
  const _AccountTypeSelector({
    super.key,
    required this.selected,
    required this.customTypes,
    required this.isEditing,
    required this.onChanged,
    required this.onAddType,
  });

  final AccountTypeChoice selected;
  final List<CustomAccountType> customTypes;
  final bool isEditing;
  final ValueChanged<AccountTypeChoice> onChanged;
  final VoidCallback onAddType;

  List<(AccountTypeChoice, String)> _options(AccountClass accountClass) => [
    for (final type in AccountType.values)
      if (type.accountClass == accountClass)
        ((type: type, customTypeId: null), accountTypeLabel(type)),
    for (final custom in customTypes)
      if (custom.baseType.accountClass == accountClass)
        ((type: custom.baseType, customTypeId: custom.id), custom.name),
  ].where((option) => !isEditing || option.$1.type == selected.type).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Values are unique: an [AccountTypeChoice] per type, the [AccountClass]
    // for each (disabled) heading, and [_newTypeItem].
    final items = <DropdownMenuItem<Object>>[];
    final labels = <String>[];
    var optionCount = 0;
    for (final accountClass in AccountClass.values) {
      final options = _options(accountClass);
      if (options.isEmpty) continue;
      items.add(
        DropdownMenuItem(
          value: accountClass,
          enabled: false,
          child: Text(
            accountClassLabel(accountClass),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      labels.add('');
      for (final (choice, label) in options) {
        items.add(
          DropdownMenuItem(
            value: choice,
            child: Padding(
              padding: const EdgeInsets.only(left: Spacing.md),
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
          ),
        );
        labels.add(label);
        optionCount++;
      }
    }
    if (!isEditing) {
      items.add(
        DropdownMenuItem(
          value: _newTypeItem,
          child: Row(
            children: [
              Icon(Icons.add, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Text(
                'New account type…',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      );
      labels.add('');
    }

    final enabled = optionCount > 1 || !isEditing;
    return DropdownButtonFormField<Object>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Type',
        helperText: !isEditing
            ? accountTypeDescription(selected.type)
            : enabled
            ? 'Can change only to a type that works the same way.'
            : "An account's type can't be changed.",
      ),
      items: items,
      // The closed field shows just the name, without the indent.
      selectedItemBuilder: (_) => [
        for (final label in labels)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      // A null callback disables the field.
      onChanged: enabled
          ? (value) => switch (value) {
              final AccountTypeChoice choice => onChanged(choice),
              _ => onAddType(),
            }
          : null,
    );
  }
}
