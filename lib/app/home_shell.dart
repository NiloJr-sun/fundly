import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/accounts/presentation/accounts_screen.dart';
import '../features/plans/presentation/plans_screen.dart';
import '../features/spending/presentation/spending_screen.dart';
import 'theme/app_colors.dart';
import 'theme/spacing.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final panel = theme.cardTheme.color ?? colors.surfaceContainerLow;
    final tabTheme = theme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.of(context).backdrop),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Theme(
          data: tabTheme,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              for (var i = 0; i < _screens.length; i++)
                // Inactive tabs keep their state but must not contribute FAB
                // heroes to route transitions from the visible tab.
                HeroMode(enabled: i == _selectedIndex, child: _screens[i]),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            Spacing.sm,
          ),
          child: Material(
            color: panel,
            elevation: 3,
            shadowColor: colors.shadow.withValues(alpha: 0.12),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              height: 72,
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
          ),
        ),
      ),
    );
  }
}
