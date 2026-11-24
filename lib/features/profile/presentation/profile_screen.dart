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
import '../../sync/presentation/edit_guard.dart';
import 'appearance_section.dart';
import 'profile_greeting_card.dart';
import 'profile_tiles.dart';

/// The Account & Spaces tab (labelled Profile in the navigation bar): who is
/// using Fundly, their spaces, their data backups, and signing out.
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
      appBar: AppBar(title: const Text('Account & Spaces')),
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
          const ProfileSectionLabel('Your data'),
          if (lastCopy != null) _CopiedNote(lastCopy),
          ProfileActionGroup(
            children: [
              // Device data only ever goes into Personal (Decision C2-8).
              if (deviceHasData && (!signedIn || personalShown))
                ProfileActionTile(
                  icon: Icons.drive_folder_upload,
                  title: "Copy this device's data",
                  subtitle: 'Into your account, checked record by record',
                  onTap: (_) => openCopyDeviceData(context),
                ),
              ProfileActionTile(
                icon: Icons.ios_share,
                title: 'Export backup',
                subtitle: space == null
                    ? 'Save all your records to a file'
                    : 'Save all records in $space to a file',
                onTap: (origin) => exportBackup(context, ref, origin: origin),
              ),
              ProfileActionTile(
                icon: Icons.restore,
                title: 'Restore from backup',
                subtitle: space == null
                    ? 'Replace all records with a backup file'
                    : 'Replace all records in $space with a backup file',
                onTap: (origin) {
                  if (canEditOrExplain(context)) {
                    restoreBackup(context, ref, origin: origin);
                  }
                },
              ),
              ProfileActionTile(
                icon: Icons.delete_forever,
                title: 'Reset all data',
                subtitle: !signedIn
                    ? 'Delete every record on this phone'
                    : space == null
                    ? 'Delete every record in your account'
                    : 'Delete every record in $space',
                destructive: true,
                onTap: (origin) {
                  if (canEditOrExplain(context)) {
                    resetData(context, ref, origin: origin);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          const AppearanceSection(),
          if (signedIn) ...[
            const SizedBox(height: Spacing.lg),
            ProfileActionGroup(
              children: [
                ProfileActionTile(
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
