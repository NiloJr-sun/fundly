import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/centered_message.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../auth/presentation/google_logo_tile.dart';
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
    final theme = Theme.of(context);
    return PopupMenuButton<_MoreAction>(
      tooltip: 'More',
      // Matches the app's dialogs and the login page: rounded, panel colour.
      color: theme.dialogTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        if (signedIn)
          _item(_MoreAction.signOut, const Icon(Icons.logout), 'Sign out')
        else if (canSignIn)
          _item(
            _MoreAction.signIn,
            const GoogleLogoTile(size: 24),
            'Sign in with Google',
          ),
        if (signedIn || canSignIn) const PopupMenuDivider(),
        _item(
          _MoreAction.exportBackup,
          const Icon(Icons.ios_share),
          'Export backup',
        ),
        _item(
          _MoreAction.restoreBackup,
          const Icon(Icons.restore),
          'Restore from backup',
        ),
      ],
    );
  }

  static PopupMenuItem<_MoreAction> _item(
    _MoreAction action,
    Widget leading,
    String title,
  ) => PopupMenuItem(
    value: action,
    child: Builder(
      builder: (context) => ListTile(
        contentPadding: EdgeInsets.zero,
        iconColor: Theme.of(context).colorScheme.primary,
        leading: SizedBox(width: 24, child: Center(child: leading)),
        title: Text(title),
      ),
    ),
  );

  /// Where this menu button is on screen, for the iPad share sheet.
  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
