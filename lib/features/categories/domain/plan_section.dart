import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import 'category.dart';

/// The sections the Plans tab and the Categories screen show, in order.
///
/// Display only: the stored [PlanGroup] is unchanged. Debt rows (stored in
/// [PlanGroup.liability]) split by their linked account's base type, so
/// custom credit and loan types follow the built-ins. Spending categories
/// the user put in the Liability group stay in [liability].
enum PlanSection { spending, savings, creditCardPayments, loans, liability }

/// The section [category] shows in. A debt row whose account is unknown
/// (detached, or not loaded yet) falls back to [PlanSection.liability].
PlanSection planSectionOf(
  Category category,
  Map<String, Account> accountsById,
) {
  final accountType = accountsById[category.linkedAccountId]?.type;
  return switch ((category.planGroup, accountType)) {
    (PlanGroup.liability, AccountType.credit) => PlanSection.creditCardPayments,
    (PlanGroup.liability, AccountType.loan) => PlanSection.loans,
    (PlanGroup.liability, _) => PlanSection.liability,
    (PlanGroup.savings, _) => PlanSection.savings,
    (PlanGroup.spending, _) => PlanSection.spending,
  };
}
