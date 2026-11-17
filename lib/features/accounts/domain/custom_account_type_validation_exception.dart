/// Why a custom account type could not be created, updated or deleted.
enum CustomAccountTypeValidationError {
  nameEmpty,
  nameTooLong,

  /// Another custom type already uses this name, or it is the name of a
  /// built-in type (ignoring case).
  nameTaken,

  /// An account, active or archived, uses the type, so it cannot be
  /// deleted.
  inUse,

  /// An account, active or archived, uses the type, so its base type (and
  /// class) cannot change.
  baseTypeInUse,
}

class CustomAccountTypeValidationException implements Exception {
  const CustomAccountTypeValidationException(this.error);

  final CustomAccountTypeValidationError error;

  @override
  String toString() => 'CustomAccountTypeValidationException(${error.name})';
}
