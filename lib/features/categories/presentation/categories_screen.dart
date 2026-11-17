import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/widgets/centered_message.dart';
import '../domain/category.dart';
import 'categories_providers.dart';
import 'category_display.dart';
import 'category_form_screen.dart';

const double _floatingButtonClearance = 88;

/// Lists categories by kind, with archived ones in their own section.
/// Tap a category to rename, archive or delete it.
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
        ),
        AsyncError() => const CenteredMessage(
          'Your categories could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CategoryFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const CenteredMessage('No categories yet.');
    final active = categories.where((category) => !category.isArchived);
    final archived = categories.where((category) => category.isArchived);
    final children = <Widget>[
      for (final kind in CategoryKind.values)
        if (active.any((category) => category.kind == kind)) ...[
          _SectionHeader(title: categoryKindLabel(kind)),
          for (final category in active.where((c) => c.kind == kind))
            _CategoryTile(category: category),
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
  const _CategoryTile({required this.category, this.showKind = false});

  final Category category;
  final bool showKind;

  @override
  Widget build(BuildContext context) {
    // A spending category's Plans group shows unless it is the default.
    final group =
        category.kind == CategoryKind.spending &&
            category.planGroup != PlanGroup.spending
        ? planGroupLabel(category.planGroup)
        : null;
    final details = [if (showKind) categoryKindLabel(category.kind), ?group];
    return ListTile(
      title: Text(category.name),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CategoryFormScreen(category: category),
        ),
      ),
    );
  }
}
