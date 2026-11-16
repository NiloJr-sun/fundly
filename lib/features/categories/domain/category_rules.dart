/// Longest allowed category name, after trimming.
const int maxCategoryNameLength = 40;

/// Why a category name is not acceptable.
enum CategoryNameError {
  /// Empty, or only whitespace.
  empty,

  /// Longer than [maxCategoryNameLength] characters after trimming.
  tooLong,
}

/// Checks a user-entered category name. Returns `null` when it is valid.
///
/// Callers must store `name.trim()`. Uniqueness is checked by the data layer,
/// which can see the other categories.
CategoryNameError? validateCategoryName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return CategoryNameError.empty;
  if (trimmed.length > maxCategoryNameLength) return CategoryNameError.tooLong;
  return null;
}
