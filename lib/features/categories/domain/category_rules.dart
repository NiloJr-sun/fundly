import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';
import 'category.dart';

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

/// Checks a default Target before it is stored. Only unlinked spending
/// categories have one, in PHP, zero or positive. The form only offers valid
/// values, so a broken rule is a programming error ([ArgumentError]).
void requireValidDefaultTarget(
  Money? target, {
  required CategoryKind kind,
  required bool isLinked,
}) {
  if (target == null) return;
  if (kind != CategoryKind.spending || isLinked) {
    throw ArgumentError.value(
      target,
      'defaultTarget',
      'Only spending categories managed here have a default Target.',
    );
  }
  if (target.currencyCode != Account.defaultCurrency) {
    throw ArgumentError.value(
      target.currencyCode,
      'currencyCode',
      'Only ${Account.defaultCurrency} targets are supported.',
    );
  }
  if (target.isNegative) {
    throw ArgumentError.value(
      target,
      'defaultTarget',
      'A default Target cannot be negative.',
    );
  }
}
