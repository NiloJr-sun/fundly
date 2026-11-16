import 'transaction_rules.dart';

/// Thrown when a transaction breaks one or more rules. [errors] holds every
/// problem found, so a form can show them all at once.
class TransactionValidationException implements Exception {
  TransactionValidationException(Set<TransactionValidationError> errors)
    : errors = Set.unmodifiable(errors);

  final Set<TransactionValidationError> errors;

  @override
  String toString() =>
      'TransactionValidationException(${errors.map((e) => e.name).join(', ')})';
}
