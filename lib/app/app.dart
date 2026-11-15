import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'theme/app_theme.dart';

/// Root widget of the Fundly app.
///
/// Follows the device's light or dark setting.
class FundlyApp extends StatelessWidget {
  const FundlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fundly',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}
