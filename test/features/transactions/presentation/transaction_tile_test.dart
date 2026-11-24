import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/core/database/record_id.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/presentation/transaction_tile.dart';

import '../../../helpers/provider_overrides.dart';
import '../domain/transaction_fixtures.dart';

/// Every transaction row colours its amount by the sign it shows.
void main() {
  final money = AppColors.fromShade(AppPalette.fallback.light);

  Future<(String, Color?)> shown(
    WidgetTester tester,
    Transaction transaction, {
    String? accountId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(
          accounts.values.toList(),
          transactions: [transaction],
          categories: categories.values.toList(),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: transaction,
              accountId: accountId,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text =
        tester.widget<ListTile>(find.byType(ListTile)).trailing! as Text;
    return (text.data!, text.style?.color);
  }

  Color? neutral(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(TransactionTile)))
          .textTheme
          .bodyLarge
          ?.color;

  testWidgets('spending is red and inflow green', (tester) async {
    expect(await shown(tester, saved(spending(), id: recordIdOf(1))), (
      '-₱500.00',
      money.expense,
    ));
    expect(await shown(tester, saved(inflow(), id: recordIdOf(2))), (
      '+₱30,000.00',
      money.positive,
    ));
  });

  testWidgets('a transfer is neutral in the full list (rule 5)', (
    tester,
  ) async {
    final (text, color) = await shown(
      tester,
      saved(transfer(), id: recordIdOf(3)),
    );
    expect(text, '₱2,000.00');
    expect(color, neutral(tester));
  });

  testWidgets('in an account, a transfer is red where it leaves and green '
      'where it arrives', (tester) async {
    final move = saved(transfer(), id: recordIdOf(4));
    expect(await shown(tester, move, accountId: move.sourceAccountId), (
      '-₱2,000.00',
      money.expense,
    ));
    expect(await shown(tester, move, accountId: move.destinationAccountId), (
      '+₱2,000.00',
      money.positive,
    ));
  });
}
