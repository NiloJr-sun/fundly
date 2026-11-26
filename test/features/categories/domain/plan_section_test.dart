import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/domain/plan_section.dart';

import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  Category category(PlanGroup group, {String? linkedAccountId}) => Category(
    id: '1',
    name: 'Row',
    kind: CategoryKind.spending,
    planGroup: group,
    linkedAccountId: linkedAccountId,
  );

  PlanSection sectionOf(Category category) => planSectionOf(category, accounts);

  test('spending and savings categories keep their group', () {
    expect(sectionOf(category(PlanGroup.spending)), PlanSection.spending);
    expect(sectionOf(category(PlanGroup.savings)), PlanSection.savings);
  });

  test('a Credit account row is under Credit card payments', () {
    expect(
      sectionOf(category(PlanGroup.liability, linkedAccountId: rcbcCardId)),
      PlanSection.creditCardPayments,
    );
  });

  test('a Loan account row is under Loans', () {
    expect(
      sectionOf(category(PlanGroup.liability, linkedAccountId: carLoanId)),
      PlanSection.loans,
    );
  });

  test('a Liability-group category without an account stays in Liability', () {
    expect(sectionOf(category(PlanGroup.liability)), PlanSection.liability);
  });

  test('a debt row whose account is unknown falls back to Liability', () {
    expect(
      sectionOf(category(PlanGroup.liability, linkedAccountId: 'missing')),
      PlanSection.liability,
    );
  });
}
