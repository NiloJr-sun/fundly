import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../auth/presentation/sign_in_actions.dart';
import '../../backup/presentation/export_backup.dart';
import '../../backup/presentation/restore_backup.dart';
import 'profile_greeting_card.dart';

/// The Profile tab: who is using Fundly, their data backups, and signing out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authIdentityProvider) is SignedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          0,
          Spacing.md,
          Spacing.lg,
        ),
        children: [
          const ProfileGreetingCard(),
          const SizedBox(height: Spacing.lg),
          const _SectionLabel('Your data'),
          _ActionGroup(
            children: [
              _ActionTile(
                icon: Icons.ios_share,
                title: 'Export backup',
                subtitle: 'Save all your records to a file',
                onTap: (origin) => exportBackup(context, ref, origin: origin),
              ),
              _ActionTile(
                icon: Icons.restore,
                title: 'Restore from backup',
                subtitle: 'Replace all records with a backup file',
                onTap: (origin) => restoreBackup(context, ref, origin: origin),
              ),
            ],
          ),
          if (signedIn) ...[
            const SizedBox(height: Spacing.lg),
            _ActionGroup(
              children: [
                _ActionTile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  onTap: (_) => signOut(context, ref),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xs, 0, 0, Spacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A rounded panel of actions with dividers between them.
class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Receives where the tile is on screen, for the iPad share sheet.
  final void Function(Rect? origin) onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return ListTile(
      leading: Icon(icon),
      iconColor: Theme.of(context).colorScheme.primary,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onTap(_originOf(context)),
    );
  }

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
