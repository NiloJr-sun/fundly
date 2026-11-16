/// Why a category could not be created, renamed or deleted.
enum CategoryValidationError {
  nameEmpty,
  nameTooLong,

  /// Another category, of either kind and active or archived, already uses
  /// this name (ignoring case).
  nameTaken,

  /// A transaction uses the category, so it can only be archived.
  inUse,
}

class CategoryValidationException implements Exception {
  const CategoryValidationException(this.error);

  final CategoryValidationError error;

  @override
  String toString() => 'CategoryValidationException(${error.name})';
}
