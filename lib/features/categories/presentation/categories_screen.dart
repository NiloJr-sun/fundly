import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/presentation/account_display.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../sync/presentation/edit_guard.dart';
import '../domain/category.dart';
import 'categories_providers.dart';
import 'category_display.dart';
import 'category_form_screen.dart';

const double _floatingButtonClearance = 88;

/// Lists categories in sections: Spending, Liability, Inflow and Archived.
/// Tap a category to rename, archive or delete it.
///
/// Liability holds spending categories in the Liability Plans group and the
/// automatic debt rows of Credit and Loan accounts. A debt row's form only
/// sets its default Target; its name and archive status follow its account.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: switch (categories) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No categories yet.',
        ),
        AsyncData(value: final list) => _CategoryList(
          categories: list.where((c) => c.linkedAccountId == null).toList(),
          debtRows: [
            for (final category in list)
              if (category.linkedAccountId != null &&
                  !category.isArchived &&
                  !category.isPlanDeleted)
                category,
          ],
        ),
        AsyncError() => const CenteredMessage(
          'Your categories could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!canEditOrExplain(context)) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CategoryFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories, required this.debtRows});

  /// The user's own categories (no debt rows).
  final List<Category> categories;

  /// Active debt rows linked to Credit and Loan accounts.
  final List<Category> debtRows;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && debtRows.isEmpty) {
      return const CenteredMessage('No categories yet.');
    }
    final active = categories.where((category) => !category.isArchived);
    final archived = categories.where((category) => category.isArchived);
    bool isLiability(Category category) =>
        category.kind == CategoryKind.spending &&
        category.planGroup == PlanGroup.liability;
    final spending = active.where(
      (c) => c.kind == CategoryKind.spending && !isLiability(c),
    );
    final liability = active.where(isLiability);
    final inflow = active.where((c) => c.kind == CategoryKind.inflow);
    final children = <Widget>[
      if (spending.isNotEmpty) ...[
        _SectionHeader(title: categoryKindLabel(CategoryKind.spending)),
        for (final category in spending) _CategoryTile(category: category),
      ],
      if (liability.isNotEmpty || debtRows.isNotEmpty) ...[
        _SectionHeader(title: planGroupLabel(PlanGroup.liability)),
        for (final category in liability)
          _CategoryTile(category: category, inGroupSection: true),
        for (final row in debtRows) _DebtRowTile(row: row),
      ],
      if (inflow.isNotEmpty) ...[
        _SectionHeader(title: categoryKindLabel(CategoryKind.inflow)),
        for (final category in inflow) _CategoryTile(category: category),
      ],
      if (archived.isNotEmpty) ...[
        const _SectionHeader(title: 'Archived'),
        for (final category in archived)
          _CategoryTile(category: category, showKind: true),
      ],
    ];
    return ListView(
      // Keep the last row clear of the floating "Add category" button.
      padding: const EdgeInsets.only(bottom: _floatingButtonClearance),
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    this.showKind = false,
    this.inGroupSection = false,
  });

  final Category category;
  final bool showKind;

  /// Shown under its Plans group's own heading, so the group is not repeated.
  final bool inGroupSection;

  @override
  Widget build(BuildContext context) {
    // A spending category's Plans group shows unless it is the default.
    final group =
        !inGroupSection &&
            category.kind == CategoryKind.spending &&
            category.planGroup != PlanGroup.spending
        ? planGroupLabel(category.planGroup)
        : null;
    final details = [if (showKind) categoryKindLabel(category.kind), ?group];
    return ListTile(
      title: Text(category.name),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (!canEditOrExplain(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CategoryFormScreen(category: category),
          ),
        );
      },
    );
  }
}

/// A Credit or Loan account's automatic Plans row. Tapping opens the form
/// for its default Target; its name and archive status follow the account.
class _DebtRowTile extends ConsumerWidget {
  const _DebtRowTile({required this.row});

  final Category row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsByIdProvider)[row.linkedAccountId];
    final type = account == null
        ? null
        : accountTypeName(account, ref.watch(customAccountTypesByIdProvider));
    return ListTile(
      title: Text(row.name),
      subtitle: Text(['From account', ?type].join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (!canEditOrExplain(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CategoryFormScreen(category: row),
          ),
        );
      },
    );
  }
}
