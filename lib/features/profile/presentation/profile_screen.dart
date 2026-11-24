import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_version.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../auth/presentation/sign_in_actions.dart';
import '../../backup/data/device_copy_store.dart';
import '../../backup/data/device_data_copier.dart';
import '../../backup/presentation/copy_device_data_screen.dart';
import '../../backup/presentation/export_backup.dart';
import '../../backup/presentation/reset_data.dart';
import '../../backup/presentation/restore_backup.dart';
import '../../spaces/data/active_space.dart';
import '../../spaces/presentation/space_providers.dart';
import 'profile_greeting_card.dart';

/// The Profile tab: who is using Fundly, their data backups, and signing out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(authIdentityProvider);
    final signedIn = identity is SignedIn;
    // Shared spaces C2: actions name the active space when there are several.
    final space = ref.watch(shownSpaceNameProvider);
    final personalShown =
        identity is SignedIn &&
        ref.watch(activeSpaceIdProvider) == identity.userId;
    final deviceHasData =
        signedIn && (ref.watch(deviceHasDataProvider).value ?? false);
    final lastCopy = signedIn
        ? null
        : ref.watch(deviceCopyStateProvider).lastCopy;
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
          if (lastCopy != null) _CopiedNote(lastCopy),
          _ActionGroup(
            children: [
              // Device data only ever goes into Personal (Decision C2-8).
              if (deviceHasData && (!signedIn || personalShown))
                _ActionTile(
                  icon: Icons.drive_folder_upload,
                  title: "Copy this device's data",
                  subtitle: 'Into your account, checked record by record',
                  onTap: (_) => openCopyDeviceData(context),
                ),
              _ActionTile(
                icon: Icons.ios_share,
                title: 'Export backup',
                subtitle: space == null
                    ? 'Save all your records to a file'
                    : 'Save all records in $space to a file',
                onTap: (origin) => exportBackup(context, ref, origin: origin),
              ),
              _ActionTile(
                icon: Icons.restore,
                title: 'Restore from backup',
                subtitle: space == null
                    ? 'Replace all records with a backup file'
                    : 'Replace all records in $space with a backup file',
                onTap: (origin) => restoreBackup(context, ref, origin: origin),
              ),
              _ActionTile(
                icon: Icons.delete_forever,
                title: 'Reset all data',
                subtitle: !signedIn
                    ? 'Delete every record on this phone'
                    : space == null
                    ? 'Delete every record in your account'
                    : 'Delete every record in $space',
                destructive: true,
                onTap: (origin) => resetData(context, ref, origin: origin),
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
          const SizedBox(height: Spacing.lg),
          const _VersionLine(),
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

/// Says where this device's signed-out data was last copied (cloud sync
/// S6.2), so a second copy of the same records is not a surprise.
class _CopiedNote extends StatelessWidget {
  const _CopiedNote(this.copy);

  final DeviceCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xs, 0, 0, Spacing.sm),
      child: Text(
        "This device's data was copied to ${copy.email} on "
        '${DateFormatter.localDate(copy.copiedAt)}.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The app's version and build, quietly at the bottom of Profile.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        appVersionText,
        style: theme.textTheme.bodySmall?.copyWith(
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
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Shows the icon and title in the error colour, for actions that delete.
  final bool destructive;

  /// Receives where the tile is on screen, for the iPad share sheet.
  final void Function(Rect? origin) onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      iconColor: destructive ? colorScheme.error : colorScheme.primary,
      title: Text(
        title,
        style: destructive ? TextStyle(color: colorScheme.error) : null,
      ),
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
