import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/custom_account_type.dart';
import '../../accounts/presentation/account_display.dart';
import '../../accounts/presentation/accounts_providers.dart';

/// An account field in the transaction form. Shows the chosen account as
/// "name · type" and, when tapped, opens a sheet listing [accounts] with a
/// search field, so a long list (many loans, say) is easy to narrow down.
///
/// [value] is owned by the form; [validator] reports its errors.
class AccountPickerField extends ConsumerWidget {
  const AccountPickerField({
    super.key,
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final List<Account> accounts;
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customTypes = ref.watch(customAccountTypesByIdProvider);
    final selected = accounts.where((account) => account.id == value);
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) => InkWell(
        onTap: () async {
          final id = await _showAccountSheet(
            context,
            title: label,
            accounts: accounts,
            selectedId: value,
            customTypes: customTypes,
          );
          if (id == null) return;
          state.didChange(id);
          onChanged(id);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: state.errorText,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          isEmpty: selected.isEmpty,
          child: selected.isEmpty
              ? null
              : Text(
                  _accountLabel(selected.first, customTypes),
                  maxLines: 1,
                  // Long account names shrink with an ellipsis instead of
                  // overflowing on narrow phones.
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}

String _accountLabel(
  Account account,
  Map<String, CustomAccountType> customTypes,
) =>
    '${account.name} · ${accountTypeName(account, customTypes)}'
    '${account.isArchived ? ' (archived)' : ''}';

/// Lets the user pick one of [accounts], searching by name or type. Returns
/// the chosen account's ID, or `null` if dismissed.
Future<String?> _showAccountSheet(
  BuildContext context, {
  required String title,
  required List<Account> accounts,
  required String? selectedId,
  required Map<String, CustomAccountType> customTypes,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _AccountSheet(
      title: title,
      accounts: accounts,
      selectedId: selectedId,
      customTypes: customTypes,
    ),
  ),
);

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({
    required this.title,
    required this.accounts,
    required this.selectedId,
    required this.customTypes,
  });

  final String title;
  final List<Account> accounts;
  final String? selectedId;
  final Map<String, CustomAccountType> customTypes;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  String _query = '';

  bool _matches(Account account) {
    final query = _query.trim().toLowerCase();
    return account.name.toLowerCase().contains(query) ||
        accountTypeName(
          account,
          widget.customTypes,
        ).toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = widget.accounts.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Text(widget.title, style: theme.textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search accounts',
              prefixIcon: Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final account in shown)
                ListTile(
                  title: Text(account.name),
                  subtitle: Text(
                    '${accountTypeName(account, widget.customTypes)}'
                    '${account.isArchived ? ' · archived' : ''}',
                  ),
                  trailing: account.id == widget.selectedId
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(account.id),
                ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Text(
                    'No account matches "${_query.trim()}".',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
