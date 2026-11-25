import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/transactions/domain/transaction_kind.dart';
import 'package:fundly/features/transactions/presentation/transaction_display.dart';

import '../domain/transaction_fixtures.dart';

void main() {
  group('transactionAmountText without an account', () {
    test('spending is negative, inflow positive', () {
      expect(transactionAmountText(spending(amount: 50000)), '-₱500.00');
      expect(transactionAmountText(inflow(amount: 3000000)), '+₱30,000.00');
    });

    test('transfers and card payments are unsigned', () {
      expect(transactionAmountText(transfer(amount: 200000)), '₱2,000.00');
      expect(transactionAmountText(cardPayment(amount: 300000)), '₱3,000.00');
    });
  });

  group('transactionAmountText for one account', () {
    test(
      'a transfer is negative at the source, positive at the destination',
      () {
        final move = transfer(amount: 200000);

        expect(transactionAmountText(move, accountId: bdoId), '-₱2,000.00');
        expect(transactionAmountText(move, accountId: walletId), '+₱2,000.00');
      },
    );

    test('a card payment reduces cash and adds to the card', () {
      final payment = cardPayment(amount: 300000);

      expect(transactionAmountText(payment, accountId: bdoId), '-₱3,000.00');
      expect(
        transactionAmountText(payment, accountId: rcbcCardId),
        '+₱3,000.00',
      );
    });

    test('a card purchase is negative on the card', () {
      expect(
        transactionAmountText(
          spending(from: rcbcCardId, amount: 50000),
          accountId: rcbcCardId,
        ),
        '-₱500.00',
      );
    });
  });

  test('transactionTitle falls back to the type name', () {
    expect(transactionTitle(spending(payee: 'Jollibee')), 'Jollibee');
    expect(transactionTitle(transfer()), 'Transfer');
    expect(transactionTitle(cardPayment()), 'Credit card payment');
  });

  test('transactionTitle uses the kind when given', () {
    final payment = transfer(to: carLoanId);

    expect(
      transactionTitle(payment, kind: TransactionKind.loanPayment),
      'Loan payment',
    );
    expect(transactionTypeLabel(payment.type), 'Transfer');
  });

  test('a loan or card payment without a payee is titled by the account '
      'paid', () {
    expect(
      transactionTitle(
        transfer(to: carLoanId),
        kind: TransactionKind.loanPayment,
        destinationName: 'Car Loan',
      ),
      'Car Loan',
    );
    expect(
      transactionTitle(
        cardPayment(),
        kind: TransactionKind.creditCardPayment,
        destinationName: 'RCBC Credit',
      ),
      'RCBC Credit',
    );
    expect(
      transactionTitle(
        transfer(to: carLoanId, payee: 'November due'),
        kind: TransactionKind.loanPayment,
        destinationName: 'Car Loan',
      ),
      'November due',
      reason: 'a payee wins',
    );
    expect(
      transactionTitle(
        transfer(),
        kind: TransactionKind.transfer,
        destinationName: 'Cash Wallet',
      ),
      'Transfer',
      reason: 'plain transfers keep their type name',
    );
    expect(
      transactionTitle(
        transfer(to: carLoanId),
        kind: TransactionKind.loanPayment,
      ),
      'Loan payment',
      reason: 'the account is not known yet',
    );
  });

  test('R.20: Spending and Inflow are titled by their category', () {
    expect(transactionTitle(spending(), categoryName: 'Food'), 'Food');
    expect(transactionTitle(inflow(), categoryName: 'Salary'), 'Salary');
    expect(transactionTitle(spending(payee: ''), categoryName: 'Food'), 'Food');
    expect(
      transactionTitle(spending(category: null)),
      'SM Supermarket',
      reason: 'no category: the payee',
    );
    expect(
      transactionTitle(spending(category: null, payee: '')),
      'Spending',
      reason: 'neither: the type name',
    );
    expect(
      transactionTitle(transfer(payee: 'Rent'), categoryName: 'Food'),
      'Rent',
      reason: 'transfers are never titled by a category',
    );
  });

  test('the picker separates Transfer from Loan payment', () {
    expect(
      transactionKindDescription(TransactionKind.transfer),
      'Move money between your accounts',
    );
    expect(
      transactionKindDescription(TransactionKind.loanPayment),
      'Pay off a loan',
    );
  });
}
