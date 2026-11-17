import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/domain/category_validation_exception.dart';
import 'package:fundly/features/categories/presentation/category_form_screen.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';

import '../../../helpers/fake_category_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  late FakeCategoryRepository repository;

  setUp(() => repository = FakeCategoryRepository());

  const food = Category(id: foodId, name: 'Food', kind: CategoryKind.spending);
  const gifts = Category(
    id: giftsId,
    name: 'Gifts',
    kind: CategoryKind.spending,
    isArchived: true,
  );

  /// Opens the form from a placeholder page so finishing can pop.
  Future<void> openForm(
    WidgetTester tester, {
    Category? editing,
    List<Transaction> transactions = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(
          accounts.values.toList(),
          transactions: transactions,
          categories: categories.values.toList(),
          categoryRepository: repository,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CategoryFormScreen(category: editing),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.widgetWithText(TextFormField, 'Name');

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDelete(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
  }

  group('New category', () {
    testWidgets('adds a spending category by default', (tester) async {
      await openForm(tester);

      await tester.enterText(nameField(), 'Groceries');
      await tapButton(tester, 'Add category');

      expect(repository.created.single, (
        name: 'Groceries',
        kind: CategoryKind.spending,
        planGroup: PlanGroup.spending,
      ));
      expect(find.text('Category added'), findsOneWidget);
      expect(find.byType(CategoryFormScreen), findsNothing);
    });

    testWidgets('adds an inflow category', (tester) async {
      await openForm(tester);

      await tester.tap(find.text('Spending'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inflow').last);
      await tester.pumpAndSettle();
      await tester.enterText(nameField(), 'Freelance');
      await tapButton(tester, 'Add category');

      expect(repository.created.single.kind, CategoryKind.inflow);
    });

    testWidgets('requires a name', (tester) async {
      await openForm(tester);

      await tapButton(tester, 'Add category');

      expect(find.text('Enter a name.'), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('shows a duplicate name reported by the repository', (
      tester,
    ) async {
      await openForm(tester);
      repository.failWith = CategoryValidationError.nameTaken;

      await tester.enterText(nameField(), 'food');
      await tapButton(tester, 'Add category');

      expect(
        find.text('You already have a category with this name.'),
        findsOneWidget,
      );
      expect(find.byType(CategoryFormScreen), findsOneWidget);
    });

    testWidgets('has no archive or delete actions', (tester) async {
      await openForm(tester);

      expect(find.text('Archive category'), findsNothing);
      expect(find.text('Delete category'), findsNothing);
    });
  });

  group('Editing', () {
    testWidgets('renames; the kind cannot change', (tester) async {
      await openForm(tester, editing: food);

      expect(find.text("A category's kind can't be changed."), findsOneWidget);

      await tester.enterText(nameField(), 'Groceries');
      await tapButton(tester, 'Save changes');

      expect(repository.renamed.single, (id: foodId, name: 'Groceries'));
      expect(find.text('Changes saved'), findsOneWidget);
    });

    testWidgets('archives an active category', (tester) async {
      await openForm(tester, editing: food);

      await tapButton(tester, 'Archive category');

      expect(repository.archivedChanges.single, (id: foodId, archived: true));
      expect(find.text('Food archived'), findsOneWidget);
      expect(find.byType(CategoryFormScreen), findsNothing);
    });

    testWidgets('unarchives an archived category', (tester) async {
      await openForm(tester, editing: gifts);

      await tapButton(tester, 'Unarchive category');

      expect(repository.archivedChanges.single, (id: giftsId, archived: false));
      expect(find.text('Gifts restored'), findsOneWidget);
    });

    testWidgets('deletes an unused category after confirming', (tester) async {
      await openForm(tester, editing: food);

      await tapButton(tester, 'Delete category');
      expect(find.text('Delete Food?'), findsOneWidget);
      await confirmDelete(tester);

      expect(repository.deleted, [foodId]);
      expect(find.text('Food deleted'), findsOneWidget);
      expect(find.byType(CategoryFormScreen), findsNothing);
    });

    testWidgets('cancelling the confirmation deletes nothing', (tester) async {
      await openForm(tester, editing: food);

      await tapButton(tester, 'Delete category');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.deleted, isEmpty);
      expect(find.byType(CategoryFormScreen), findsOneWidget);
    });

    testWidgets('a category used by a transaction cannot be deleted', (
      tester,
    ) async {
      await openForm(
        tester,
        editing: food,
        transactions: [saved(spending(category: foodId))],
      );

      expect(find.text('Delete category'), findsNothing);
      expect(
        find.text(
          'Used by transactions, so it can be archived but not deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Archive category'), findsOneWidget);
    });

    testWidgets('explains when the repository finds it in use', (tester) async {
      await openForm(tester, editing: food);
      repository.failWith = CategoryValidationError.inUse;

      await tapButton(tester, 'Delete category');
      await confirmDelete(tester);

      expect(
        find.text('This category is used by transactions. Archive it instead.'),
        findsOneWidget,
      );
      expect(find.byType(CategoryFormScreen), findsOneWidget);
    });
  });
}
