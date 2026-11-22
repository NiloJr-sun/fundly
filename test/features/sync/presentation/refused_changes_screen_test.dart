import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_database.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/sync/presentation/refused_changes_screen.dart';
import 'package:fundly/features/sync/presentation/sync_status_line.dart';

import '../../../helpers/fake_synced_store.dart';

const user = SignedIn(userId: 'u1', email: 'a@test.com');

Future<void> refuse(
  FakeSyncedStore store,
  String batchId,
  String name, {
  String code = 'revision_conflict',
  String at = '2026-11-22T08:00:00.000Z',
}) => store.database
    .into(store.database.syncRejections)
    .insert(
      SyncRejectionsCompanion.insert(
        batchId: batchId,
        kind: 'rejected',
        code: Value(code),
        operations: jsonEncode({
          'version': 1,
          'items': [
            {
              'operation': 'category.create',
              'id': '00000000-0000-4000-8000-00000000000$batchId',
              'data': {
                'name': name,
                'kind': 'spending',
                'plan_group': 'spending',
              },
            },
          ],
        }),
        createdIds: '[]',
        labels: '{}',
        rejectedAt: at,
      ),
    );

void main() {
  late FakeSyncedStore store;

  setUp(() => store = FakeSyncedStore(user));
  tearDown(() => store.close());

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncedStoreProvider.overrideWithValue(store)],
        child: MaterialApp(home: Scaffold(body: home)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('lists refused changes newest first and dismisses one', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await refuse(store, '1', 'Gifts', at: '2026-11-21T08:00:00.000Z');
      await refuse(store, '2', 'Travel', code: 'name_taken');
    });
    await pump(tester, const RefusedChangesScreen());

    final titles = tester
        .widgetList<Text>(find.textContaining('Add category'))
        .map((text) => text.data)
        .toList();
    expect(titles, ['Add category · Travel', 'Add category · Gifts']);
    expect(find.textContaining('The name is already used'), findsOneWidget);
    expect(
      find.textContaining('Changed on another device first'),
      findsOneWidget,
    );

    await tester.tap(find.text('Add category · Gifts'));
    await tester.pumpAndSettle();
    expect(find.text('Name: Gifts'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Dismiss'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Add category · Gifts'), findsNothing);
    expect(find.text('Add category · Travel'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('dismiss all asks first, then empties the list', (tester) async {
    await tester.runAsync(() async {
      await refuse(store, '1', 'Gifts');
      await refuse(store, '2', 'Travel');
    });
    await pump(tester, const RefusedChangesScreen());

    await tester.tap(find.text('Dismiss all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Add category'), findsNWidgets(2));

    await tester.tap(find.text('Dismiss all'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Dismiss all'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('No refused changes.'), findsOneWidget);
    expect(find.text('Dismiss all'), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    'the status line opens the list only when something was refused',
    (tester) async {
      await pump(tester, const SyncStatusLine());
      expect(find.text('Up to date'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);

      await tester.runAsync(() => refuse(store, '1', 'Gifts'));
      await tester.pumpAndSettle();
      expect(
        find.text('Up to date · 1 change refused · Review'),
        findsOneWidget,
      );

      await tester.tap(find.textContaining('Review'));
      await tester.pumpAndSettle();
      expect(find.text('Refused changes'), findsOneWidget);
      expect(find.text('Add category · Gifts'), findsOneWidget);
      await unmount(tester);
    },
  );
}
