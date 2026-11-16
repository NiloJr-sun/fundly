/// The four transaction types (CLAUDE.md §3).
enum TransactionType {
  /// Money leaving an asset account, or a purchase charged to a credit card.
  spending,

  /// Money received into an account.
  inflow,

  /// Money moved between two of the user's own accounts. Also used for loan
  /// payments (G4).
  transfer,

  /// Money moved from an asset account to a credit card (G5).
  creditCardPayment;

  /// Whether money leaves a source account.
  bool get hasSourceAccount => this != TransactionType.inflow;

  /// Whether money arrives in a destination account.
  bool get hasDestinationAccount => this != TransactionType.spending;

  /// Counted in spending totals. Transfers and credit-card payments move money
  /// between the user's own accounts and are never spending (rules 5 and 6).
  bool get countsAsSpending => this == TransactionType.spending;

  /// Counted in inflow totals (rule 5).
  bool get countsAsInflow => this == TransactionType.inflow;
}
