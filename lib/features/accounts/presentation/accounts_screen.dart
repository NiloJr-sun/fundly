import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/centered_message.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../auth/presentation/sign_in_actions.dart';
import '../../auth/presentation/signed_in_banner.dart';
import '../../backup/presentation/export_backup.dart';
import '../../backup/presentation/restore_backup.dart';
import 'account_form_screen.dart';
import 'account_list.dart';
import 'account_types_screen.dart';
import 'accounts_providers.dart';
import 'archived_accounts_screen.dart';

/// The Account tab: lists the user's active accounts.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(activeAccountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Account types',
            icon: const Icon(Icons.label_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountTypesScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Archived accounts',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ArchivedAccountsScreen(),
              ),
            ),
          ),
          const _MoreMenu(),
        ],
      ),
      body: Column(
        children: [
          const SignedInBanner(),
          Expanded(
            child: switch (accounts) {
              AsyncData(value: final list) when list.isEmpty =>
                const CenteredMessage(
                  'No accounts yet.\nAdd your savings, credit cards and loans '
                  'to start tracking your balances.',
                ),
              AsyncData(value: final list) => AccountList(accounts: list),
              AsyncError() => const CenteredMessage(
                'Your accounts could not be loaded. Please restart the app.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
    );
  }
}

enum _MoreAction { exportBackup, restoreBackup, signIn, signOut }

/// The ⋮ menu for app-level actions: backups, and signing in or out when this
/// build supports it.
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSignIn = ref.watch(authRepositoryProvider).canSignIn;
    final signedIn = ref.watch(authIdentityProvider) is SignedIn;
    return PopupMenuButton<_MoreAction>(
      tooltip: 'More',
      onSelected: (action) => switch (action) {
        _MoreAction.exportBackup => exportBackup(
          context,
          ref,
          origin: _originOf(context),
        ),
        _MoreAction.restoreBackup => restoreBackup(
          context,
          ref,
          origin: _originOf(context),
        ),
        _MoreAction.signIn => signInWithGoogle(context, ref),
        _MoreAction.signOut => signOut(context, ref),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _MoreAction.exportBackup,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.ios_share),
            title: Text('Export backup'),
          ),
        ),
        const PopupMenuItem(
          value: _MoreAction.restoreBackup,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.restore),
            title: Text('Restore from backup'),
          ),
        ),
        if (signedIn)
          const PopupMenuItem(
            value: _MoreAction.signOut,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text('Sign out'),
            ),
          )
        else if (canSignIn)
          const PopupMenuItem(
            value: _MoreAction.signIn,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.login),
              title: Text('Sign in with Google'),
            ),
          ),
      ],
    );
  }

  /// Where this menu button is on screen, for the iPad share sheet.
  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
