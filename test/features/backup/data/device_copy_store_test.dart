import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/device_copy_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const counts = BackupCounts(
    customAccountTypes: 1,
    accounts: 4,
    categories: 5,
    transactions: 5,
    monthlyPlans: 2,
  );
  final state = DeviceCopyState(
    copies: [
      DeviceCopy(
        userId: 'u1',
        email: 'a@test.com',
        copiedAt: DateTime.utc(2026, 11, 22, 7),
      ),
    ],
    dismissed: const {'u2'},
    pending: const PendingCopyCheck(
      userId: 'u3',
      email: 'c@test.com',
      ids: {
        'accounts': {'1': 'uuid-1'},
        'transactions': {},
      },
      counts: counts,
    ),
  );

  test('the state survives the preferences round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDeviceCopyStore(
      await SharedPreferences.getInstance(),
    );
    expect(store.read().copies, isEmpty);

    await store.write(state);
    final read = store.read();
    expect(read.lastCopy?.email, 'a@test.com');
    expect(read.lastCopy?.copiedAt, DateTime.utc(2026, 11, 22, 7));
    expect(read.dismissed, {'u2'});
    expect(read.pending?.ids, {
      'accounts': {'1': 'uuid-1'},
      'transactions': <String, String>{},
    });
    expect(read.pending?.counts, counts);
  });

  test('unreadable preferences start over instead of failing', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesDeviceCopyStore.key: '{"copies": 3}',
    });
    final store = SharedPreferencesDeviceCopyStore(
      await SharedPreferences.getInstance(),
    );
    expect(store.read().copies, isEmpty);
  });

  test('settledFor covers copied, dismissed and pending accounts', () {
    expect(state.settledFor('u1'), isTrue);
    expect(state.settledFor('u2'), isTrue);
    expect(state.settledFor('u3'), isTrue);
    expect(state.settledFor('u4'), isFalse);
  });

  test('recording a checked copy clears the pending check', () async {
    final store = InMemoryDeviceCopyStore(state);
    final container = ProviderContainer(
      overrides: [deviceCopyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(deviceCopyStateProvider.notifier);

    await notifier.recordCopy(
      DeviceCopy(
        userId: 'u1',
        email: 'a@test.com',
        copiedAt: DateTime.utc(2026, 11, 23),
      ),
    );

    final saved = store.read();
    expect(saved.pending, isNull);
    // A second copy to the same account replaces the first.
    expect(saved.copies, hasLength(1));
    expect(saved.lastCopy?.copiedAt, DateTime.utc(2026, 11, 23));
    expect(saved.dismissed, {'u2'});
  });
}
