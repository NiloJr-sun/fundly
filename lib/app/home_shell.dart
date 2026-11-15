import 'package:flutter/material.dart';

import '../features/accounts/presentation/accounts_screen.dart';
import '../features/plans/presentation/plans_screen.dart';
import '../features/spending/presentation/spending_screen.dart';

/// Top-level navigation: Spending, Plans and Account tabs.
///
/// Uses an [IndexedStack] so each tab keeps its state (such as scroll
/// position) when the user switches away and back.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    SpendingScreen(),
    PlansScreen(),
    AccountsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Spending',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
