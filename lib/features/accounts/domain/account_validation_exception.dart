/// Why an account could not be created, updated or deleted.
enum AccountValidationError {
  nameEmpty,
  nameTooLong,

  /// Another account, active or archived, already uses this name (ignoring
  /// case).
  nameTaken,
  negativeOpeningBalance,

  /// A transaction uses the account, so it cannot be deleted (G7). It can
  /// only stay archived.
  hasTransactions,
}

class AccountValidationException implements Exception {
  const AccountValidationException(this.error);

  final AccountValidationError error;

  @override
  String toString() => 'AccountValidationException(${error.name})';
}
