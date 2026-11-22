import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/sync/presentation/sync_status_line.dart';

void main() {
  String text(
    SyncConnection connection, {
    bool synced = true,
    int hidden = 0,
    int pending = 0,
  }) => syncStatusText(
    SyncState(connection: connection, hasSynced: synced, error: 'timeout'),
    hiddenRows: hidden,
    pendingUploads: pending,
  );

  test('every state has its own text', () {
    expect(text(SyncConnection.connected), 'Up to date');
    expect(
      text(SyncConnection.connected, synced: false),
      'Downloading your data…',
    );
    expect(text(SyncConnection.connecting, synced: false), 'Connecting…');
    expect(
      text(SyncConnection.connecting),
      'Reconnecting · showing data saved on this device',
    );
    expect(
      text(SyncConnection.offline),
      'Offline · showing data saved on this device',
    );
    expect(text(SyncConnection.failed), 'Sync problem, retrying: timeout');
    expect(
      text(SyncConnection.notConfigured),
      'Sync is not set up in this build',
    );
    expect(
      text(SyncConnection.stuck),
      'Sync stuck: the server refused a change (timeout). It is kept on '
      'this device',
    );
    expect(syncStatusText(null), 'Opening your data…');
  });

  test('changes waiting to upload are counted', () {
    expect(
      text(SyncConnection.connected, pending: 1),
      'Uploading · 1 change waiting to upload',
    );
    expect(
      text(SyncConnection.offline, pending: 2),
      'Offline · showing data saved on this device · 2 changes waiting to '
      'upload',
    );
  });

  test('waiting changes say why the last upload attempt failed', () {
    String retrying(SyncConnection connection, {int pending = 3}) =>
        syncStatusText(
          SyncState(
            connection: connection,
            hasSynced: true,
            error: 'timeout',
            uploadRetry: 'PGRST301',
          ),
          pendingUploads: pending,
        );

    expect(
      retrying(SyncConnection.connected),
      'Uploading · 3 changes waiting to upload (retrying: PGRST301)',
    );
    expect(retrying(SyncConnection.connected, pending: 0), 'Up to date');
    expect(
      retrying(SyncConnection.failed),
      'Sync problem, retrying: timeout · 3 changes waiting to upload',
    );
    expect(retrying(SyncConnection.stuck), isNot(contains('PGRST301')));
  });

  test('hidden rows are reported', () {
    expect(
      text(SyncConnection.connected, hidden: 1),
      'Up to date · 1 record hidden: its amount is too large to show',
    );
    expect(
      text(SyncConnection.connected, hidden: 3),
      contains('3 records hidden'),
    );
  });
}
