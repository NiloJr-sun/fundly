import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../categories/presentation/categories_screen.dart';

/// Placeholder for budgeting (roadmap Phase 4). Categories are managed from
/// here.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: Text(
            'Budgeting is planned for a future release.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
