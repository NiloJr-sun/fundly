import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/data/default_categories.dart';
import 'package:fundly/features/categories/domain/category.dart';

void main() {
  late AppDatabase database;
  late CategoryRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepository(database);
  });

  tearDown(() => database.close());

  test(
    'a new database is seeded with the default categories in order',
    () async {
      final categories = await repository.watchAll().first;

      expect(
        categories.map((c) => (name: c.name, kind: c.kind)).toList(),
        defaultCategories,
      );
    },
  );

  test('filters spending categories, keeping "Other" last', () async {
    final names = (await repository.watchAll(kind: CategoryKind.spending).first)
        .map((c) => c.name);

    expect(names, [
      'Food',
      'Transport',
      'Utilities',
      'Subscriptions',
      'Shopping',
      'Health',
      'Other',
    ]);
  });

  test('filters inflow categories', () async {
    final names = (await repository.watchAll(kind: CategoryKind.inflow).first)
        .map((c) => c.name);

    expect(names, ['Salary', 'Other income']);
  });

  group('database constraints', () {
    Future<void> insertRaw(String name, String kind) =>
        database.customStatement(
          'INSERT INTO categories (name, kind) VALUES (?, ?)',
          [name, kind],
        );

    test('rejects a duplicate name ignoring case', () {
      expect(insertRaw('food', 'spending'), throwsA(isA<Exception>()));
    });

    test('rejects an unknown kind', () {
      expect(insertRaw('Gifts', 'transfer'), throwsA(isA<Exception>()));
    });

    test('rejects empty and over-long names', () {
      expect(insertRaw('', 'spending'), throwsA(isA<Exception>()));
      expect(insertRaw('a' * 41, 'spending'), throwsA(isA<Exception>()));
    });

    test('accepts a valid new category', () async {
      await insertRaw('Gifts', 'spending');

      final names = (await repository.watchAll().first).map((c) => c.name);
      expect(names, contains('Gifts'));
    });
  });

  test('foreign keys are enabled', () async {
    final result = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();

    expect(result.read<int>('foreign_keys'), 1);
  });
}
