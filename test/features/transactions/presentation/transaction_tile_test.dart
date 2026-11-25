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

  testWidgets('only card purchases without a category are Not in Plans', (
    tester,
  ) async {
    await shown(
      tester,
      saved(spending(from: rcbcCardId, category: null), id: recordIdOf(1)),
    );
    expect(find.textContaining('RCBC Credit · Not in Plans'), findsOneWidget);

    await shown(tester, saved(spending(from: rcbcCardId), id: recordIdOf(2)));
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('RCBC Credit'), findsOneWidget);
    expect(find.textContaining('Not in Plans'), findsNothing);

    await shown(tester, saved(spending(), id: recordIdOf(3)));
    expect(find.textContaining('Not in Plans'), findsNothing);
  });

  testWidgets('G4: a transfer into a loan shows as a Loan payment', (
    tester,
  ) async {
    final (text, color) = await shown(
      tester,
      saved(transfer(to: carLoanId), id: recordIdOf(5)),
    );
    expect(find.byIcon(Icons.request_quote_outlined), findsOneWidget);
    expect(text, '₱2,000.00', reason: 'unsigned, like other transfers');
    expect(color, neutral(tester));

    await shown(tester, saved(transfer(), id: recordIdOf(6)));
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    expect(find.textContaining('BDO Savings → Cash Wallet'), findsOneWidget);
  });

  group('R.20: Spending and Inflow are titled by their category', () {
    testWidgets('the payee moves to the details line', (tester) async {
      await shown(tester, saved(spending(), id: recordIdOf(1)));
      expect(find.text('Food'), findsOneWidget);
      expect(
        find.text('Nov 16, 2026 · SM Supermarket · BDO Savings'),
        findsOneWidget,
      );

      await shown(tester, saved(inflow(), id: recordIdOf(2)));
      expect(find.text('Salary'), findsOneWidget);
      expect(find.textContaining('Employer'), findsOneWidget);
    });

    testWidgets('without a payee, only the date and account', (tester) async {
      await shown(tester, saved(spending(payee: ''), id: recordIdOf(3)));
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Nov 16, 2026 · BDO Savings'), findsOneWidget);
    });

    testWidgets('without a category, the payee, else the type name', (
      tester,
    ) async {
      await shown(
        tester,
        saved(spending(from: rcbcCardId, category: null), id: recordIdOf(4)),
      );
      expect(find.text('SM Supermarket'), findsOneWidget);

      await shown(
        tester,
        saved(
          spending(from: rcbcCardId, category: null, payee: ''),
          id: recordIdOf(5),
        ),
      );
      expect(find.text('Spending'), findsOneWidget);

      await shown(
        tester,
        saved(inflow(category: null, payee: ''), id: recordIdOf(6)),
      );
      expect(find.text('Inflow'), findsOneWidget);
    });
  });

  group('a debt payment without a payee is titled by the account paid', () {
    testWidgets('a loan payment', (tester) async {
      await shown(tester, saved(transfer(to: carLoanId), id: recordIdOf(5)));
      expect(find.text('Car Loan'), findsOneWidget);
      expect(find.textContaining('From BDO Savings'), findsOneWidget);
      expect(find.text('Loan payment'), findsNothing);
      expect(find.textContaining('→'), findsNothing);
    });

    testWidgets('a credit card payment', (tester) async {
      await shown(tester, saved(cardPayment(), id: recordIdOf(7)));
      expect(find.text('RCBC Credit'), findsOneWidget);
      expect(find.textContaining('From BDO Savings'), findsOneWidget);
      expect(find.text('Credit card payment'), findsNothing);
    });

    testWidgets('a payee still wins, with both accounts shown', (tester) async {
      await shown(
        tester,
        saved(
          transfer(to: carLoanId, payee: 'November due'),
          id: recordIdOf(8),
        ),
      );
      expect(find.text('November due'), findsOneWidget);
      expect(find.textContaining('BDO Savings → Car Loan'), findsOneWidget);
    });
  });
}
