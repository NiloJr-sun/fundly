import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/database_name.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';

void main() {
  const userId = '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d';

  test('signed out keeps the original database name', () {
    expect(databaseNameFor(const SignedOut()), 'fundly');
    expect(localDatabaseName, 'fundly');
  });

  test('each signed-in user gets their own database', () {
    expect(
      databaseNameFor(const SignedIn(userId: userId, email: 'a@test.com')),
      'fundly_sync_$userId',
    );
    expect(
      databaseNameFor(
        const SignedIn(
          userId: '00000000-0000-4000-8000-000000000001',
          email: 'b@test.com',
        ),
      ),
      isNot(databaseNameFor(const SignedIn(userId: userId, email: ''))),
    );
  });

  test('the name depends on the user ID, not the email', () {
    expect(
      databaseNameFor(const SignedIn(userId: userId, email: 'old@test.com')),
      databaseNameFor(const SignedIn(userId: userId, email: 'new@test.com')),
    );
  });

  test('upper-case UUIDs map to the same lower-case name', () {
    expect(
      databaseNameFor(SignedIn(userId: userId.toUpperCase(), email: '')),
      'fundly_sync_$userId',
    );
  });

  test('anything that is not a UUID is rejected', () {
    for (final bad in [
      '',
      '../fundly',
      'fundly',
      '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d/../../x',
      '3f2b8c1e9a4d4e7b8c215d6f7a8b9c0d',
    ]) {
      expect(
        () => databaseNameFor(SignedIn(userId: bad, email: '')),
        throwsArgumentError,
        reason: bad,
      );
      expect(
        () => previewDatabaseNameFor(bad),
        throwsArgumentError,
        reason: bad,
      );
    }
  });

  test('the S4 preview database keeps its old name, apart from the store', () {
    expect(previewDatabaseNameFor(userId), 'fundly_user_$userId');
    expect(
      previewDatabaseNameFor(userId),
      isNot(databaseNameFor(const SignedIn(userId: userId, email: ''))),
    );
  });

  group('space stores (shared spaces C2)', () {
    const space = '7c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5';

    test('Personal keeps the store it has had since S5.2', () {
      expect(syncedDatabaseNameFor(userId, userId), 'fundly_sync_$userId');
      expect(
        syncedDatabaseNameFor(userId, userId),
        databaseNameFor(const SignedIn(userId: userId, email: '')),
      );
    });

    test('another space gets its own store, per user', () {
      expect(
        syncedDatabaseNameFor(userId, space),
        'fundly_sync_${userId}_$space',
      );
      expect(
        syncedDatabaseNameFor('00000000-0000-4000-8000-000000000001', space),
        isNot(syncedDatabaseNameFor(userId, space)),
      );
    });

    test('ids that are not UUIDs are refused', () {
      expect(() => syncedDatabaseNameFor(userId, '../x'), throwsArgumentError);
      expect(
        syncedDatabaseNameFor(userId, space.toUpperCase()),
        'fundly_sync_${userId}_$space',
      );
    });
  });
}
