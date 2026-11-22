import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/batch_uploader.dart';
import 'package:fundly/core/sync/powersync_store.dart';
import 'package:fundly/core/sync/synced_store.dart';

void main() {
  const refused = SyncUploadException(
    UploadOutcome.blocked,
    'unsupported_operation',
  );
  const offline = SyncUploadException(
    UploadOutcome.transient,
    'SocketException',
  );

  SyncState map({
    bool connected = true,
    Object? downloadError,
    Object? uploadError,
    SyncUploadException? lastUploadFailure,
  }) => syncStateFor(
    connected: connected,
    connecting: false,
    hasSynced: true,
    lastSyncedAt: null,
    downloadError: downloadError,
    uploadError: uploadError,
    lastUploadFailure: lastUploadFailure,
  );

  test('a refused upload is stuck when the error keeps its type (native)', () {
    final state = map(uploadError: refused);

    expect(state.connection, SyncConnection.stuck);
    expect(state.error, 'unsupported_operation');
  });

  test('a refused upload is stuck when the error arrives as text (web)', () {
    final state = map(
      uploadError: 'unsupported_operation',
      lastUploadFailure: refused,
    );

    expect(state.connection, SyncConnection.stuck);
    expect(state.error, 'unsupported_operation');
  });

  test('a temporary upload failure stays connected, on both platforms', () {
    expect(map(uploadError: offline).connection, SyncConnection.connected);
    expect(
      map(
        uploadError: 'SocketException',
        lastUploadFailure: offline,
      ).connection,
      SyncConnection.connected,
    );
  });

  test('an untyped upload error without a record is not shown as stuck', () {
    final state = map(uploadError: 'something else');

    expect(state.connection, SyncConnection.connected);
    expect(state.error, isNull);
  });

  test('a recorded failure is ignored once the status has no upload error', () {
    final state = map(lastUploadFailure: refused);

    expect(state.connection, SyncConnection.connected);
    expect(state.error, isNull);
  });

  test('a download error wins over a refused upload', () {
    final state = map(
      downloadError: 'network down',
      uploadError: 'unsupported_operation',
      lastUploadFailure: refused,
    );

    expect(state.connection, SyncConnection.failed);
    expect(state.error, 'network down');
  });

  test('without errors the connection flags decide', () {
    expect(map().connection, SyncConnection.connected);
    expect(map(connected: false).connection, SyncConnection.offline);
    expect(
      syncStateFor(
        connected: false,
        connecting: true,
        hasSynced: false,
        lastSyncedAt: null,
        downloadError: null,
        uploadError: null,
      ),
      const SyncState(connection: SyncConnection.connecting),
    );
  });
}
