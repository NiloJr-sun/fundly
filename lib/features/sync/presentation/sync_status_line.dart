import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_store.dart';

/// What the Profile tab says about signed-in sync (S5.2: downloads only, so
/// every state also says the data is view-only).
String syncStatusText(SyncState? state, {int hiddenRows = 0}) {
  final status = switch (state) {
    null => 'Opening your data…',
    SyncState(connection: SyncConnection.notConfigured) =>
      'Sync is not set up in this build',
    SyncState(connection: SyncConnection.failed, :final error) =>
      'Sync problem, retrying${error == null ? '' : ': $error'}',
    SyncState(connection: SyncConnection.offline) =>
      'Offline · showing data saved on this device',
    SyncState(connection: SyncConnection.connecting, hasSynced: false) =>
      'Connecting…',
    SyncState(connection: SyncConnection.connected, hasSynced: false) =>
      'Downloading your data…',
    SyncState(connection: SyncConnection.connecting) =>
      'Reconnecting · showing data saved on this device',
    SyncState(connection: SyncConnection.connected) => 'Up to date',
  };
  final hidden = switch (hiddenRows) {
    0 => '',
    1 => ' · 1 record hidden: its amount is too large to show',
    _ => ' · $hiddenRows records hidden: their amounts are too large to show',
  };
  return '$status$hidden · View only';
}

/// The signed-in sync status under the Profile greeting.
class SyncStatusLine extends ConsumerWidget {
  const SyncStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider).value;
    final hidden = ref.watch(unsafeSyncedRowCountProvider).value ?? 0;
    final theme = Theme.of(context);
    final failed = state?.connection == SyncConnection.failed || hidden > 0;
    return Text(
      syncStatusText(state, hiddenRows: hidden),
      style: theme.textTheme.bodySmall?.copyWith(
        color: failed
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
