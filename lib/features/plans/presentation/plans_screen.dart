import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';

/// Placeholder for budgeting (roadmap Phase 4).
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
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
