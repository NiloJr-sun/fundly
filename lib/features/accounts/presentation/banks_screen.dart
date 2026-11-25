import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/centered_message.dart';
import '../../sync/presentation/edit_guard.dart';
import '../domain/custom_bank.dart';
import 'accounts_providers.dart';
import 'bank_dialog.dart';
import 'bank_display.dart';

const double _floatingButtonClearance = 88;

/// Lists the banks the user added (docs/BANKS_PLAN.md, B-8). Tap one to
/// rename it, or delete it while no account belongs to it. Built-in banks
/// are always in the bank picker and are not listed here.
class BanksScreen extends ConsumerWidget {
  const BanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(customBanksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Banks')),
      body: switch (banks) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No banks added yet.\nMajor banks and e-wallets are already in '
          'the list. Add yours if it is missing.',
        ),
        AsyncData(value: final list) => _BankList(banks: list),
        AsyncError() => const CenteredMessage(
          'Your banks could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (canEditOrExplain(context)) showNewBankDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add bank'),
      ),
    );
  }
}

class _BankList extends ConsumerWidget {
  const _BankList({required this.banks});

  /// Ordered by name.
  final List<CustomBank> banks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(customBankAccountCountsProvider);
    return ListView(
      // Keep the last row clear of the floating "Add bank" button.
      padding: const EdgeInsets.only(bottom: _floatingButtonClearance),
      children: [
        for (final bank in banks)
          _BankTile(bank: bank, accountCount: counts[bank.id] ?? 0),
      ],
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({required this.bank, required this.accountCount});

  final CustomBank bank;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: BankAvatar(badge: customBankBadge(bank)),
      title: Text(bank.name),
      subtitle: Text(switch (accountCount) {
        0 => 'No accounts',
        1 => '1 account',
        _ => '$accountCount accounts',
      }),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (!canEditOrExplain(context)) return;
        showEditBankDialog(context, bank: bank, accountCount: accountCount);
      },
    );
  }
}
