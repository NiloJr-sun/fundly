import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import 'transaction_fixtures.dart';

typedef E = TransactionValidationError;

Set<E> validate(TransactionDraft draft, {Transaction? existing}) =>
    validateTransaction(
      draft,
      accounts: accounts,
      categories: categories,
      existing: existing,
    );

TransactionDraft withNote(TransactionDraft draft, String note) =>
    TransactionDraft(
      type: draft.type,
      amount: draft.amount,
      date: draft.date,
      payee: draft.payee,
      categoryId: draft.categoryId,
      sourceAccountId: draft.sourceAccountId,
      destinationAccountId: draft.destinationAccountId,
      note: note,
    );

void main() {
  group('valid transactions of every type', () {
    test('spending from savings and from a credit card', () {
      expect(validate(spending()), isEmpty);
      expect(validate(spending(from: rcbcCardId)), isEmpty);
    });

    test('inflow into savings and a card refund; category optional', () {
      expect(validate(inflow()), isEmpty);
      expect(validate(inflow(to: rcbcCardId, category: null)), isEmpty);
    });

    test('transfer between asset accounts and to a loan', () {
      expect(validate(transfer()), isEmpty);
      expect(validate(transfer(to: carLoanId)), isEmpty);
    });

    test('credit card payment', () {
      expect(validate(cardPayment()), isEmpty);
    });
  });

  group('Rule 7: no transfer from an account to itself', () {
    test('transfer', () {
      expect(
        validate(transfer(from: bdoId, to: bdoId)),
        contains(E.sameSourceAndDestination),
      );
    });

    test('credit card payment', () {
      expect(
        validate(cardPayment(from: rcbcCardId, to: rcbcCardId)),
        contains(E.sameSourceAndDestination),
      );
    });
  });

  group('Rule 8: amounts must be positive', () {
    for (final amount in [0, -1, -50000]) {
      test('$amount is rejected for every type', () {
        for (final draft in [
          spending(amount: amount),
          inflow(amount: amount),
          transfer(amount: amount),
          cardPayment(amount: amount),
        ]) {
          expect(validate(draft), {E.amountNotPositive}, reason: '$draft');
        }
      });
    }
  });

  group('Rule 12: account and category references are validated', () {
    test('unknown accounts', () {
      expect(validate(spending(from: '99')), {E.sourceAccountNotFound});
      expect(validate(inflow(to: '99')), {E.destinationAccountNotFound});
    });

    test('unknown category', () {
      expect(validate(spending(category: '99')), {E.categoryNotFound});
    });

    test('missing accounts per type', () {
      expect(validate(spending(from: null)), {E.sourceAccountMissing});
      expect(validate(inflow(to: null)), {E.destinationAccountMissing});
      expect(validate(transfer(from: null, to: null)), {
        E.sourceAccountMissing,
        E.destinationAccountMissing,
      });
    });

    test('accounts a type does not use are rejected', () {
      expect(validate(spending(to: walletId)), {
        E.destinationAccountNotAllowed,
      });
      expect(validate(inflow(from: walletId)), {E.sourceAccountNotAllowed});
    });
  });

  group('allowed account types (CLAUDE.md §11)', () {
    test('spending cannot come from a loan', () {
      expect(validate(spending(from: carLoanId)), {E.sourceAccountWrongType});
    });

    test('inflow cannot go into a loan', () {
      expect(validate(inflow(to: carLoanId)), {E.destinationAccountWrongType});
    });

    test('G5: a transfer cannot target a credit account', () {
      expect(validate(transfer(to: rcbcCardId)), {
        E.destinationAccountWrongType,
      });
    });

    test('transfers and card payments must come from Savings/Cash', () {
      expect(validate(transfer(from: rcbcCardId, to: bdoId)), {
        E.sourceAccountWrongType,
      });
      expect(validate(transfer(from: carLoanId, to: bdoId)), {
        E.sourceAccountWrongType,
      });
      expect(validate(cardPayment(from: rcbcCardId, to: rcbcCardId)), {
        E.sourceAccountWrongType,
        E.sameSourceAndDestination,
      });
    });

    test('a card payment must go to a credit account', () {
      expect(validate(cardPayment(to: walletId)), {
        E.destinationAccountWrongType,
      });
      expect(validate(cardPayment(to: carLoanId)), {
        E.destinationAccountWrongType,
      });
    });

    test('allowed type sets match the decisions', () {
      expect(allowedSourceAccountTypes(TransactionType.spending), {
        AccountType.savingsCash,
        AccountType.credit,
      });
      expect(allowedSourceAccountTypes(TransactionType.inflow), isEmpty);
      expect(allowedDestinationAccountTypes(TransactionType.transfer), {
        AccountType.savingsCash,
        AccountType.loan,
      });
      expect(
        allowedDestinationAccountTypes(TransactionType.creditCardPayment),
        {AccountType.credit},
      );
    });
  });

  group('G7: archived accounts', () {
    test('cannot be used by a new transaction', () {
      expect(validate(spending(from: oldWalletId)), {E.sourceAccountArchived});
      expect(validate(transfer(to: oldWalletId)), {
        E.destinationAccountArchived,
      });
    });

    test('an edit may keep an archived account it already used', () {
      final original = saved(spending(from: oldWalletId));

      expect(
        validate(spending(from: oldWalletId, amount: 1), existing: original),
        isEmpty,
      );
    });

    test('an edit may not switch to an archived account', () {
      final original = saved(spending());

      expect(validate(spending(from: oldWalletId), existing: original), {
        E.sourceAccountArchived,
      });
    });
  });

  group('archived categories (task 4.1)', () {
    test('cannot be used by a new transaction', () {
      expect(validate(spending(category: giftsId)), {E.categoryArchived});
    });

    test('an edit may keep an archived category it already used', () {
      final original = saved(spending(category: giftsId));

      expect(
        validate(spending(category: giftsId, amount: 1), existing: original),
        isEmpty,
      );
    });

    test('an edit may not switch to an archived category', () {
      final original = saved(spending());

      expect(validate(spending(category: giftsId), existing: original), {
        E.categoryArchived,
      });
    });

    test('the kind is still checked first', () {
      expect(validate(inflow(category: giftsId)), {E.categoryWrongKind});
    });
  });

  group('G8: the type cannot change on edit', () {
    test('changing spending to inflow is rejected', () {
      final original = saved(spending());

      expect(validate(inflow(), existing: original), contains(E.typeChanged));
    });

    test('editing other fields is fine', () {
      final original = saved(spending());

      expect(validate(spending(amount: 999), existing: original), isEmpty);
    });
  });

  group('payee', () {
    test('required for spending and inflow', () {
      expect(validate(spending(payee: '  ')), {E.payeeMissing});
      expect(validate(inflow(payee: '')), {E.payeeMissing});
    });

    test('optional for transfers and card payments', () {
      expect(validate(transfer()), isEmpty);
      expect(validate(cardPayment()), isEmpty);
    });

    test('at most $maxPayeeLength characters after trimming', () {
      expect(validate(spending(payee: 'a' * maxPayeeLength)), isEmpty);
      expect(validate(spending(payee: ' ${'a' * maxPayeeLength} ')), isEmpty);
      expect(validate(spending(payee: 'a' * (maxPayeeLength + 1))), {
        E.payeeTooLong,
      });
    });
  });

  group('category', () {
    test('required for spending', () {
      expect(validate(spending(category: null)), {E.categoryMissing});
    });

    test('spending needs a spending category', () {
      expect(validate(spending(category: salaryId)), {E.categoryWrongKind});
    });

    test('inflow needs an inflow category when one is set', () {
      expect(validate(inflow(category: foodId)), {E.categoryWrongKind});
    });

    test('transfers and card payments have none', () {
      expect(validate(transfer(category: foodId)), {E.categoryNotAllowed});
    });
  });

  test('note at most $maxNoteLength characters', () {
    expect(validate(withNote(spending(), 'a' * maxNoteLength)), isEmpty);
    expect(validate(withNote(spending(), 'a' * (maxNoteLength + 1))), {
      E.noteTooLong,
    });
  });

  test('G6: amount currency must match the accounts', () {
    final usd = TransactionDraft(
      type: TransactionType.transfer,
      amount: const Money(minorUnits: 100, currencyCode: 'USD'),
      date: today,
      sourceAccountId: bdoId,
      destinationAccountId: walletId,
    );

    expect(validate(usd), {E.currencyMismatch});
  });

  test('reports every problem at once', () {
    final draft = TransactionDraft(
      type: TransactionType.spending,
      amount: php(0),
      date: today,
      categoryId: salaryId,
      sourceAccountId: carLoanId,
    );

    expect(validate(draft), {
      E.amountNotPositive,
      E.sourceAccountWrongType,
      E.payeeMissing,
      E.categoryWrongKind,
    });
  });
}
