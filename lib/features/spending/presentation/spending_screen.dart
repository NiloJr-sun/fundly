import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';

/// Placeholder for the Spending overview (roadmap Phase 3).
class SpendingScreen extends StatelessWidget {
  const SpendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: Text(
            'Your balances and recent activity will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
