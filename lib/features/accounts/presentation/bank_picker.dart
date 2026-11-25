import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../domain/account.dart';
import '../domain/bank.dart';
import '../domain/custom_bank.dart';
import 'accounts_providers.dart';
import 'bank_dialog.dart';
import 'bank_display.dart';

/// What the bank picker returns: the chosen [bank], where both fields `null`
/// mean No bank, and the custom bank when it was [added] from the picker, so
/// the form can show it before the custom banks list includes it.
typedef BankPick = ({AccountBank bank, CustomBank? added});

/// Lets the user pick an account's bank (docs/BANKS_PLAN.md, B-8): built-in
/// banks, then the user's own banks, then "Add a bank…" and "No bank", with
/// a search field. [selected] is ticked. Returns `null` if dismissed.
Future<BankPick?> showBankPicker(
  BuildContext context, {
  required AccountBank selected,
}) => showModalBottomSheet<BankPick>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _BankPicker(selected: selected),
  ),
);

class _BankPicker extends ConsumerStatefulWidget {
  const _BankPicker({required this.selected});

  final AccountBank selected;

  @override
  ConsumerState<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends ConsumerState<_BankPicker> {
  String _query = '';

  bool _matches(String name) =>
      name.toLowerCase().contains(_query.trim().toLowerCase());

  void _pick(AccountBank bank, {CustomBank? added}) =>
      Navigator.of(context).pop<BankPick>((bank: bank, added: added));

  Future<void> _addBank() async {
    final added = await showNewBankDialog(context);
    if (added == null || !mounted) return;
    _pick((bankKey: null, customBankId: added.id), added: added);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customBanks = ref.watch(customBanksProvider).value ?? const [];
    final builtIn = builtInBanks.where((bank) => _matches(bank.name)).toList();
    final custom = customBanks.where((bank) => _matches(bank.name)).toList();
    final selected = widget.selected;
    final nothingFound = builtIn.isEmpty && custom.isEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            0,
            Spacing.md,
            Spacing.sm,
          ),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search banks',
              prefixIcon: Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final bank in builtIn)
                _BankOption(
                  badge: builtInBankBadge(bank),
                  selected: selected.bankKey == bank.key,
                  onTap: () => _pick((bankKey: bank.key, customBankId: null)),
                ),
              if (custom.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  child: Text(
                    'Your banks',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                for (final bank in custom)
                  _BankOption(
                    badge: customBankBadge(bank),
                    selected: selected.customBankId == bank.id,
                    onTap: () => _pick((bankKey: null, customBankId: bank.id)),
                  ),
              ],
              if (nothingFound)
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Text(
                    'No bank matches "${_query.trim()}".',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.add, color: theme.colorScheme.primary),
                title: Text(
                  'Add a bank…',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                onTap: _addBank,
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('No bank'),
                subtitle: const Text('For example, a cash wallet'),
                trailing:
                    selected.bankKey == null && selected.customBankId == null
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => _pick((bankKey: null, customBankId: null)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BankOption extends StatelessWidget {
  const _BankOption({
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final BankBadge badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: BankAvatar(badge: badge, size: 36),
      title: Text(badge.name),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
