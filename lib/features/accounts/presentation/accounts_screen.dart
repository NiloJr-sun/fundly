import 'package:flutter/material.dart';

/// Placeholder for account management (roadmap Phase 1).
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Your accounts will appear here.')),
    );
  }
}
