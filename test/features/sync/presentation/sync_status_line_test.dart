import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/sync/presentation/sync_status_line.dart';

void main() {
  String text(
    SyncConnection connection, {
    bool synced = true,
    int hidden = 0,
  }) => syncStatusText(
    SyncState(connection: connection, hasSynced: synced, error: 'timeout'),
    hiddenRows: hidden,
  );

  test('every state also says the data is view-only', () {
    expect(text(SyncConnection.connected), 'Up to date · View only');
    expect(
      text(SyncConnection.connected, synced: false),
      'Downloading your data… · View only',
    );
    expect(
      text(SyncConnection.connecting, synced: false),
      'Connecting… · View only',
    );
    expect(
      text(SyncConnection.connecting),
      'Reconnecting · showing data saved on this device · View only',
    );
    expect(
      text(SyncConnection.offline),
      'Offline · showing data saved on this device · View only',
    );
    expect(
      text(SyncConnection.failed),
      'Sync problem, retrying: timeout · View only',
    );
    expect(
      text(SyncConnection.notConfigured),
      'Sync is not set up in this build · View only',
    );
    expect(syncStatusText(null), 'Opening your data… · View only');
  });

  test('hidden rows are reported', () {
    expect(
      text(SyncConnection.connected, hidden: 1),
      'Up to date · 1 record hidden: its amount is too large to show · '
      'View only',
    );
    expect(
      text(SyncConnection.connected, hidden: 3),
      contains('3 records hidden'),
    );
  });
}
