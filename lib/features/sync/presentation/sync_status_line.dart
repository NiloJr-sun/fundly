import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/sync/synced_store.dart';
import 'refused_changes_screen.dart';

/// What the Profile tab says about signed-in sync.
String syncStatusText(
  SyncState? state, {
  int hiddenRows = 0,
  int pendingUploads = 0,
  int refusedChanges = 0,
  bool isWeb = false,
}) {
  final status = switch (state) {
    null => 'Opening your data…',
    SyncState(connection: SyncConnection.notConfigured) =>
      'Sync is not set up in this build',
    SyncState(connection: SyncConnection.failed, :final error) =>
      'Sync problem, retrying${error == null ? '' : ': $error'}',
    SyncState(connection: SyncConnection.stuck, :final error) =>
      "Sync stuck: the server can't process a change yet"
          '${error == null ? '' : ' ($error)'}. It is kept on this device',
    SyncState(connection: SyncConnection.offline, hasSynced: false) =>
      "Offline · your data downloads when you're back online",
    SyncState(connection: SyncConnection.offline) =>
      'Offline · showing data saved on this device',
    SyncState(connection: SyncConnection.connecting, hasSynced: false) =>
      'Connecting…',
    SyncState(connection: SyncConnection.connected, hasSynced: false) =>
      'Downloading your data…',
    SyncState(connection: SyncConnection.connecting) =>
      'Reconnecting · showing data saved on this device',
    SyncState(connection: SyncConnection.connected) =>
      pendingUploads == 0 ? 'All changes synced' : 'Uploading',
  };
  final hidden = switch (hiddenRows) {
    0 => '',
    1 => ' · 1 record hidden: its amount is too large to show',
    _ => ' · $hiddenRows records hidden: their amounts are too large to show',
  };
  final pending = switch (pendingUploads) {
    0 => '',
    1 => ' · 1 change waiting to upload',
    _ => ' · $pendingUploads changes waiting to upload',
  };
  // A browser keeps them only in its own storage (S5.5).
  final browserOnly = isWeb && pendingUploads > 0
      ? ' · saved only in this browser until uploaded'
      : '';
  final refused = switch (refusedChanges) {
    0 => '',
    1 => ' · 1 change refused · Review',
    _ => ' · $refusedChanges changes refused · Review',
  };
  // Failed and stuck already show their error.
  final retry = switch (state) {
    _ when pendingUploads == 0 => '',
    SyncState(connection: SyncConnection.failed || SyncConnection.stuck) => '',
    SyncState(:final uploadRetry?) => ' (retrying: $uploadRetry)',
    _ => '',
  };
  return '$status$pending$retry$browserOnly$refused$hidden';
}

/// The signed-in sync status under the Account & Spaces greeting, after a
/// small dot: green when everything is synced, the error colour on a problem,
/// muted otherwise. While the server has refused changes, tapping it opens
/// the Refused changes screen.
class SyncStatusLine extends ConsumerWidget {
  const SyncStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider).value;
    final hidden = ref.watch(unsafeSyncedRowCountProvider).value ?? 0;
    final pending = ref.watch(pendingUploadCountProvider).value ?? 0;
    final refused = ref.watch(refusedChangesProvider).value?.length ?? 0;
    final theme = Theme.of(context);
    final failed =
        state?.connection == SyncConnection.failed ||
        state?.connection == SyncConnection.stuck ||
        hidden > 0 ||
        refused > 0;
    final synced =
        !failed &&
        pending == 0 &&
        state?.connection == SyncConnection.connected &&
        state!.hasSynced;
    final dotColor = failed
        ? theme.colorScheme.error
        : synced
        ? AppColors.of(context).positive
        : theme.colorScheme.onSurfaceVariant;
    final text = Text(
      syncStatusText(
        state,
        hiddenRows: hidden,
        pendingUploads: pending,
        refusedChanges: refused,
        isWeb: kIsWeb,
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        color: failed
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Centres the dot on the first line of bodySmall text.
          padding: const EdgeInsets.only(top: 5, right: 6),
          child: Container(
            key: const Key('sync-status-dot'),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        Expanded(child: text),
      ],
    );
    if (refused == 0) return line;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RefusedChangesScreen()),
      ),
      child: line,
    );
  }
}
