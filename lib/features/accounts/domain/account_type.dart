/// The kinds of account Fundly supports.
enum AccountType {
  /// Bank savings, cash wallet, emergency fund and other asset accounts.
  savingsCash,

  /// Credit cards. The balance represents an amount owed.
  credit,

  /// Loans. The balance represents outstanding debt.
  loan;

  /// Whether the balance represents money owed rather than money held.
  ///
  /// This is the only place that decides it. Under the signed-balance
  /// convention (CLAUDE.md §11, D1) a liability's balance is negative when
  /// money is owed.
  bool get isLiability => switch (this) {
    AccountType.savingsCash => false,
    AccountType.credit || AccountType.loan => true,
  };
}
