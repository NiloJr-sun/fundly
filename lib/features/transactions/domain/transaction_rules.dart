import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/domain/category.dart';
import 'transaction.dart';
import 'transaction_type.dart';

const int maxPayeeLength = 60;
const int maxNoteLength = 500;

/// Everything that can make a transaction invalid.
enum TransactionValidationError {
  /// Rule 8: amounts are entered as positive values.
  amountNotPositive,

  /// The amount's currency differs from an account's currency (G6).
  currencyMismatch,

  sourceAccountMissing,

  /// This type has no source account (inflow), but one was given.
  sourceAccountNotAllowed,
  sourceAccountNotFound,

  /// A new transaction cannot use an archived account (G7).
  sourceAccountArchived,

  /// The account type cannot be a source for this transaction type.
  sourceAccountWrongType,

  destinationAccountMissing,

  /// This type has no destination account (spending), but one was given.
  destinationAccountNotAllowed,
  destinationAccountNotFound,
  destinationAccountArchived,
  destinationAccountWrongType,

  /// Rule 7: money cannot move from an account to itself.
  sameSourceAndDestination,

  payeeTooLong,

  /// Spending requires a category, unless it is paid from a Credit account
  /// (R.18).
  categoryMissing,

  /// Transfers and card payments have no category.
  categoryNotAllowed,
  categoryNotFound,

  /// A new transaction cannot use an archived category (task 4.1).
  categoryArchived,

  /// Spending needs a spending category; inflow an inflow category.
  categoryWrongKind,

  noteTooLong,

  /// G8: an edit cannot change the transaction type.
  typeChanged,
}

/// Account types that can be the source of a [type] transaction
/// (CLAUDE.md §11). Empty when the type has no source account. A Transfer
/// from a Credit account is a cash advance.
Set<AccountType> allowedSourceAccountTypes(TransactionType type) =>
    switch (type) {
      TransactionType.spending ||
      TransactionType.transfer => {AccountType.savingsCash, AccountType.credit},
      TransactionType.inflow => const {},
      TransactionType.creditCardPayment => {AccountType.savingsCash},
    };

/// Account types that can be the destination of a [type] transaction whose
/// source account is of type [source] (`null` when not chosen yet).
/// Transfers cannot target Credit accounts (G5); loans are paid by Transfer
/// (G4). A cash advance (Transfer from Credit) goes only to Savings/Cash.
/// Empty when the type has no destination account.
Set<AccountType> allowedDestinationAccountTypes(
  TransactionType type, {
  AccountType? source,
}) => switch (type) {
  TransactionType.spending => const {},
  TransactionType.inflow => {AccountType.savingsCash, AccountType.credit},
  TransactionType.transfer when source == AccountType.credit => {
    AccountType.savingsCash,
  },
  TransactionType.transfer => {AccountType.savingsCash, AccountType.loan},
  TransactionType.creditCardPayment => {AccountType.credit},
};

/// Validates [draft] against the accounting rules (CLAUDE.md §4) and the
/// confirmed decisions in CLAUDE.md §11. Returns every problem found; an
/// empty set means the transaction is valid.
///
/// [accounts] and [categories] are looked up by id and must include archived
/// records. Pass [existing] when editing: an edit may keep an archived
/// account or category the transaction already used, but may not change the
/// type.
Set<TransactionValidationError> validateTransaction(
  TransactionDraft draft, {
  required Map<String, Account> accounts,
  required Map<String, Category> categories,
  Transaction? existing,
}) {
  final errors = <TransactionValidationError>{};
  final type = draft.type;

  if (existing != null && existing.type != type) {
    errors.add(TransactionValidationError.typeChanged);
  }

  if (draft.amount.minorUnits <= 0) {
    errors.add(TransactionValidationError.amountNotPositive);
  }

  final source = _checkAccount(
    role: _Role.source,
    accountId: draft.sourceAccountId,
    used: type.hasSourceAccount,
    allowedTypes: allowedSourceAccountTypes(type),
    previousAccountId: existing?.sourceAccountId,
    accounts: accounts,
    errors: errors,
  );
  final destination = _checkAccount(
    role: _Role.destination,
    accountId: draft.destinationAccountId,
    used: type.hasDestinationAccount,
    allowedTypes: allowedDestinationAccountTypes(type, source: source?.type),
    previousAccountId: existing?.destinationAccountId,
    accounts: accounts,
    errors: errors,
  );

  if (draft.sourceAccountId != null &&
      draft.sourceAccountId == draft.destinationAccountId) {
    errors.add(TransactionValidationError.sameSourceAndDestination);
  }

  for (final account in [?source, ?destination]) {
    if (account.currencyCode != draft.amount.currencyCode) {
      errors.add(TransactionValidationError.currencyMismatch);
    }
  }

  _checkPayee(draft, errors);
  _checkCategory(
    draft,
    categories,
    existing?.categoryId,
    errors,
    sourceType: accounts[draft.sourceAccountId]?.type,
  );

  if (draft.note.trim().length > maxNoteLength) {
    errors.add(TransactionValidationError.noteTooLong);
  }

  return errors;
}

/// Whether a [type] transaction paid from a [source] account must have a
/// category: Spending does, except a card purchase (source Credit, custom
/// credit types included), which only adds to what is owed (R.18).
bool isCategoryRequired(TransactionType type, {AccountType? source}) =>
    type == TransactionType.spending && source != AccountType.credit;

enum _Role { source, destination }

/// Checks one account role and returns the account when it is usable for the
/// currency check.
Account? _checkAccount({
  required _Role role,
  required String? accountId,
  required bool used,
  required Set<AccountType> allowedTypes,
  required String? previousAccountId,
  required Map<String, Account> accounts,
  required Set<TransactionValidationError> errors,
}) {
  final isSource = role == _Role.source;
  if (!used) {
    if (accountId != null) {
      errors.add(
        isSource
            ? TransactionValidationError.sourceAccountNotAllowed
            : TransactionValidationError.destinationAccountNotAllowed,
      );
    }
    return null;
  }
  if (accountId == null) {
    errors.add(
      isSource
          ? TransactionValidationError.sourceAccountMissing
          : TransactionValidationError.destinationAccountMissing,
    );
    return null;
  }

  final account = accounts[accountId];
  if (account == null) {
    errors.add(
      isSource
          ? TransactionValidationError.sourceAccountNotFound
          : TransactionValidationError.destinationAccountNotFound,
    );
    return null;
  }

  // An edit may keep an archived account it already used (G7).
  if (account.isArchived && accountId != previousAccountId) {
    errors.add(
      isSource
          ? TransactionValidationError.sourceAccountArchived
          : TransactionValidationError.destinationAccountArchived,
    );
  }
  if (!allowedTypes.contains(account.type)) {
    errors.add(
      isSource
          ? TransactionValidationError.sourceAccountWrongType
          : TransactionValidationError.destinationAccountWrongType,
    );
  }
  return account;
}

/// The payee is optional for every type (R.20); it only has a length limit.
void _checkPayee(
  TransactionDraft draft,
  Set<TransactionValidationError> errors,
) {
  if (draft.payee.trim().length > maxPayeeLength) {
    errors.add(TransactionValidationError.payeeTooLong);
  }
}

void _checkCategory(
  TransactionDraft draft,
  Map<String, Category> categories,
  String? previousCategoryId,
  Set<TransactionValidationError> errors, {
  required AccountType? sourceType,
}) {
  final categoryId = draft.categoryId;
  final expectedKind = switch (draft.type) {
    TransactionType.spending => CategoryKind.spending,
    TransactionType.inflow => CategoryKind.inflow,
    TransactionType.transfer || TransactionType.creditCardPayment => null,
  };

  if (expectedKind == null) {
    if (categoryId != null) {
      errors.add(TransactionValidationError.categoryNotAllowed);
    }
    return;
  }
  if (categoryId == null) {
    if (isCategoryRequired(draft.type, source: sourceType)) {
      errors.add(TransactionValidationError.categoryMissing);
    }
    return;
  }

  final category = categories[categoryId];
  if (category == null) {
    errors.add(TransactionValidationError.categoryNotFound);
  } else if (category.linkedAccountId != null) {
    errors.add(TransactionValidationError.categoryNotAllowed);
  } else if (category.kind != expectedKind) {
    errors.add(TransactionValidationError.categoryWrongKind);
  } else if (category.isArchived && categoryId != previousCategoryId) {
    // An edit may keep an archived category it already used.
    errors.add(TransactionValidationError.categoryArchived);
  }
}
