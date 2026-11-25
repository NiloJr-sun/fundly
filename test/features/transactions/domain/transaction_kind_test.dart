import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/transactions/domain/transaction_kind.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import 'transaction_fixtures.dart';

void main() {
  group('TransactionKind.of', () {
    test('G4: a transfer into a loan is a loan payment', () {
      expect(
        TransactionKind.of(
          transfer(to: carLoanId),
          destinationType: AccountType.loan,
        ),
        TransactionKind.loanPayment,
      );
    });

    test(
      'other transfers stay transfers, also when the account is unknown',
      () {
        expect(
          TransactionKind.of(
            transfer(),
            destinationType: AccountType.savingsCash,
          ),
          TransactionKind.transfer,
        );
        expect(
          TransactionKind.of(transfer(to: carLoanId)),
          TransactionKind.transfer,
        );
      },
    );

    test('other types map one to one, whatever the destination', () {
      expect(TransactionKind.of(spending()), TransactionKind.spending);
      expect(
        TransactionKind.of(inflow(), destinationType: AccountType.savingsCash),
        TransactionKind.inflow,
      );
      expect(
        TransactionKind.of(cardPayment(), destinationType: AccountType.credit),
        TransactionKind.creditCardPayment,
      );
    });

    test(
      'every kind is stored as an existing type; loan payment as transfer',
      () {
        expect(TransactionKind.loanPayment.type, TransactionType.transfer);
        for (final type in TransactionType.values) {
          expect(TransactionKind.ofType(type).type, type);
        }
      },
    );
  });

  group('account types per kind', () {
    test('a loan is paid from Savings/Cash into a Loan account', () {
      expect(sourceAccountTypesFor(TransactionKind.loanPayment), {
        AccountType.savingsCash,
      });
      expect(
        destinationAccountTypesFor(
          TransactionKind.loanPayment,
          source: AccountType.savingsCash,
        ),
        {AccountType.loan},
      );
    });

    test('a transfer no longer offers Loan accounts', () {
      expect(
        destinationAccountTypesFor(
          TransactionKind.transfer,
          source: AccountType.savingsCash,
        ),
        {AccountType.savingsCash},
      );
      expect(
        destinationAccountTypesFor(
          TransactionKind.transfer,
          source: AccountType.credit,
        ),
        {AccountType.savingsCash},
      );
      expect(sourceAccountTypesFor(TransactionKind.transfer), {
        AccountType.savingsCash,
        AccountType.credit,
      });
    });

    test('every kind offers only what the data layer accepts', () {
      for (final kind in TransactionKind.values) {
        expect(
          allowedSourceAccountTypes(kind.type),
          containsAll(sourceAccountTypesFor(kind)),
        );
        for (final source in [null, ...AccountType.values]) {
          expect(
            allowedDestinationAccountTypes(kind.type, source: source),
            containsAll(destinationAccountTypesFor(kind, source: source)),
            reason: '$kind from $source',
          );
        }
      }
    });

    test('a transfer into a loan is still valid in the data layer (G4)', () {
      expect(
        validateTransaction(
          transfer(to: carLoanId),
          accounts: accounts,
          categories: categories,
        ),
        isEmpty,
      );
    });
  });
}
