/// Why an account could not be created or updated.
enum AccountValidationError {
  nameEmpty,
  nameTooLong,

  /// Another account, active or archived, already uses this name (ignoring
  /// case).
  nameTaken,
  negativeOpeningBalance,
}

class AccountValidationException implements Exception {
  const AccountValidationException(this.error);

  final AccountValidationError error;

  @override
  String toString() => 'AccountValidationException(${error.name})';
}
