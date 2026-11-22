import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_synced_store.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);
const userB = SignedIn(
  userId: '00000000-0000-4000-8000-000000000001',
  email: 'b@test.com',
);

/// S4 Decision 3 and S5.2: signed out, the original database; signed in,
/// that user's synchronized store. Switching closes the old one, and nobody
/// sees another identity's records.
void main() {
  late Directory directory;
  late FakeAuthRepository auth;
  late ProviderContainer container;
  late List<String> opened;
  late List<String> closed;
  late Map<String, FakeSyncedStore> stores;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fundly_s4_');
    auth = FakeAuthRepository();
    opened = [];
    closed = [];
    stores = {};
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        databaseOpenerProvider.overrideWithValue((name) {
          opened.add(name);
          return AppDatabase(
            NativeDatabase(File('${directory.path}/$name.sqlite'))
                .interceptWith(_CloseRecorder(name, closed)),
          );
        }),
        syncedStoreOpenerProvider.overrideWithValue((identity) {
          opened.add(identity.userId);
          return stores[identity.userId] = FakeSyncedStore(identity);
        }),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    // Let the last database finish closing before deleting its file.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    directory.deleteSync(recursive: true);
  });

  Future<void> switchTo(AuthIdentity identity) async {
    auth.emit(identity);
    await Future<void>.delayed(Duration.zero);
  }

  AccountRepository accounts() => container.read(accountRepositoryProvider);

  Future<List<String>> accountNames() async =>
      (await accounts().watchAll().first).map((a) => a.name).toList();

  Future<void> addAccount(String name) => accounts().create(
    name: name,
    type: AccountType.savingsCash,
    enteredOpeningAmount: const Money(minorUnits: 1000, currencyCode: 'PHP'),
  );

  Future<void> download(SignedIn user, String id, String name) =>
      stores[user.userId]!.download({
        'accounts': [SyncedRows.account(id, name)],
      });

  test('opens the original database while signed out', () {
    container.read(appDatabaseProvider);
    expect(opened, ['fundly']);
  });

  test('records stay with the identity that has them', () async {
    await addAccount('Local wallet');

    await switchTo(userA);
    expect(await accountNames(), isEmpty);
    await download(userA, _idA, 'A savings');
    expect(await accountNames(), ['A savings']);

    await switchTo(userB);
    expect(await accountNames(), isEmpty);
    await download(userB, _idB, 'B savings');

    await switchTo(const SignedOut());
    expect(await accountNames(), ['Local wallet']);

    expect(opened, ['fundly', userA.userId, userB.userId, 'fundly']);
  });

  test('signed in, the original database is never opened', () async {
    await switchTo(userA);
    expect(
      () => container.read(appDatabaseProvider),
      throwsA(isA<ProviderException>()),
    );
    expect(opened, isNot(contains('fundly')));
  });

  test('signed in, records are view-only', () async {
    await switchTo(userA);
    expect(container.read(canEditProvider), isFalse);
    expect(() => addAccount('New'), throwsA(isA<ReadOnlyStoreException>()));
    await switchTo(const SignedOut());
    expect(container.read(canEditProvider), isTrue);
  });

  test('switching closes the previous store', () async {
    final local = container.read(appDatabaseProvider);
    await switchTo(userA);
    container.read(accountRepositoryProvider);
    await Future<void>.delayed(Duration.zero);
    expect(closed, ['fundly']);
    expect(local, isNotNull);

    await switchTo(userB);
    container.read(accountRepositoryProvider);
    await Future<void>.delayed(Duration.zero);
    expect(stores[userA.userId]!.closed, isTrue);
    expect(stores[userB.userId]!.closed, isFalse);
  });

  test('a token refresh for the same user keeps the store open', () async {
    await switchTo(userA);
    final store = container.read(syncedStoreProvider);
    await switchTo(userA);
    await switchTo(SignedIn(userId: userA.userId, email: 'changed@test.com'));
    expect(container.read(syncedStoreProvider), same(store));
    expect(opened, [userA.userId]);
  });
}

const _idA = '21000000-0000-4000-8000-00000000000a';
const _idB = '21000000-0000-4000-8000-00000000000b';

/// Records which database names were closed.
class _CloseRecorder extends QueryInterceptor {
  _CloseRecorder(this.name, this.closed);

  final String name;
  final List<String> closed;

  @override
  Future<void> close(QueryExecutor inner) {
    closed.add(name);
    return inner.close();
  }
}
