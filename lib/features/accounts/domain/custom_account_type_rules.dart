/// Names of the built-in account types, as shown to the user. A custom type
/// cannot use one of these (ignoring case), so the two cannot be confused.
///
/// Must match `accountTypeLabel` in the presentation layer; a test checks it.
const List<String> builtInAccountTypeNames = [
  'Savings / Cash',
  'Credit',
  'Loan',
];

/// Whether [name] (already trimmed) is a built-in type's name, ignoring case.
bool isBuiltInAccountTypeName(String name) {
  final lower = name.toLowerCase();
  return builtInAccountTypeNames.any(
    (builtIn) => builtIn.toLowerCase() == lower,
  );
}
