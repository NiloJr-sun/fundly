import '../domain/category.dart';
import '../domain/category_rules.dart';
import '../domain/category_validation_exception.dart';
import '../domain/plan_section.dart';

String categoryKindLabel(CategoryKind kind) => switch (kind) {
  CategoryKind.spending => 'Spending',
  CategoryKind.inflow => 'Inflow',
};

/// The heading of a [PlanGroup] on the Plans page.
String planGroupLabel(PlanGroup group) => switch (group) {
  PlanGroup.spending => 'Spending',
  PlanGroup.savings => 'Savings',
  PlanGroup.liability => 'Liability',
};

/// The heading of a [PlanSection] on the Plans tab and Categories screen.
String planSectionLabel(PlanSection section) => switch (section) {
  PlanSection.spending => 'Spending',
  PlanSection.savings => 'Savings',
  PlanSection.creditCardPayments => 'Credit card payments',
  PlanSection.loans => 'Loans',
  PlanSection.liability => 'Liability',
};

String categoryNameErrorText(CategoryNameError error) => switch (error) {
  CategoryNameError.empty => 'Enter a name.',
  CategoryNameError.tooLong =>
    'Use $maxCategoryNameLength characters or fewer.',
};

/// Message for an error reported by the repository.
String categoryValidationErrorText(CategoryValidationError error) =>
    switch (error) {
      CategoryValidationError.nameEmpty => 'Enter a name.',
      CategoryValidationError.nameTooLong =>
        'Use $maxCategoryNameLength characters or fewer.',
      CategoryValidationError.nameTaken =>
        'You already have a category with this name.',
      CategoryValidationError.inUse =>
        'This category is used by transactions. Archive it instead.',
    };
