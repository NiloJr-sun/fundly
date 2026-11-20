import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';

import '../../helpers/fake_auth_repository.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);
const userB = SignedIn(
  userId: '00000000-0000-4000-8000-000000000001',
  email: 'b@test.com',
);

/// S4 Decision 3: each identity has its own database file, switching closes
/// the old one, and nobody sees another identity's records.
void main() {
  late Directory directory;
  late FakeAuthRepository auth;
  late ProviderContainer container;
  late List<String> opened;
  late List<String> closed;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fundly_s4_');
    auth = FakeAuthRepository();
    opened = [];
    closed = [];
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

  test('opens the original database while signed out', () {
    container.read(appDatabaseProvider);
    expect(opened, ['fundly']);
  });

  test('records stay with the identity that wrote them', () async {
    await addAccount('Local wallet');

    await switchTo(userA);
    expect(await accountNames(), isEmpty);
    await addAccount('A savings');

    await switchTo(userB);
    expect(await accountNames(), isEmpty);
    await addAccount('B savings');

    await switchTo(const SignedOut());
    expect(await accountNames(), ['Local wallet']);

    await switchTo(userA);
    expect(await accountNames(), ['A savings']);

    expect(opened, [
      'fundly',
      'fundly_user_${userA.userId}',
      'fundly_user_${userB.userId}',
      'fundly',
      'fundly_user_${userA.userId}',
    ]);
  });

  test('a new user database starts with the default categories', () async {
    await switchTo(userA);
    final database = container.read(appDatabaseProvider);
    final categories = await database.select(database.categories).get();
    expect(categories, isNotEmpty);
  });

  test('switching closes the previous database', () async {
    final local = container.read(appDatabaseProvider);
    await switchTo(userA);
    expect(container.read(appDatabaseProvider), isNot(same(local)));
    await Future<void>.delayed(Duration.zero);
    expect(closed, ['fundly']);
  });

  test('a token refresh for the same user keeps the database open', () async {
    await switchTo(userA);
    final database = container.read(appDatabaseProvider);
    await switchTo(userA);
    await switchTo(SignedIn(userId: userA.userId, email: 'changed@test.com'));
    expect(container.read(appDatabaseProvider), same(database));
    expect(opened.where((name) => name != 'fundly'), hasLength(1));
  });
}

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
