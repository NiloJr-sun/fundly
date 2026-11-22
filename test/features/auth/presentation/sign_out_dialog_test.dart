import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/auth/presentation/sign_out_dialog.dart';

void main() {
  late StreamController<int> pending;
  bool? answer;

  setUp(() {
    pending = StreamController<int>();
    answer = null;
  });
  tearDown(() => pending.close());

  Future<void> open(
    WidgetTester tester, {
    SyncConnection connection = SyncConnection.connected,
    bool isWeb = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingUploadCountProvider.overrideWith((ref) => pending.stream),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(
              SyncState(connection: connection, hasSynced: true),
            ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => answer = await showDialog<bool>(
                context: context,
                builder: (_) => SignOutDialog(isWeb: isWeb),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing waiting, it is the usual confirmation', (
    tester,
  ) async {
    pending.add(0);
    await open(tester);

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });

  testWidgets('waiting changes are warned about and kept', (tester) async {
    pending.add(2);
    await open(tester);

    expect(find.text("2 changes haven't uploaded yet"), findsOneWidget);
    expect(
      find.textContaining(
        'they stay on this device and upload the next time you sign in here',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Sync is stuck'), findsNothing);
    expect(find.textContaining('browser'), findsNothing);
    expect(find.text('Sign out'), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out anyway'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });

  testWidgets('the count is live and turns into the usual confirmation', (
    tester,
  ) async {
    pending.add(1);
    await open(tester);
    expect(find.text("1 change hasn't uploaded yet"), findsOneWidget);

    pending.add(0);
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    // It does not sign out by itself.
    expect(answer, isNull);
  });

  testWidgets('a stuck queue and the web are explained', (tester) async {
    pending.add(1);
    await open(tester, connection: SyncConnection.stuck, isWeb: true);

    expect(
      find.textContaining("a change can't upload until the app or server"),
      findsOneWidget,
    );
    expect(
      find.textContaining("Clearing this browser's site data deletes"),
      findsOneWidget,
    );
  });
}
