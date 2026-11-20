import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_name.dart';
import '../features/auth/data/auth_repository.dart';
import 'home_shell.dart';
import 'theme/app_theme.dart';

/// Root widget of the Fundly app.
///
/// Follows the device's light or dark setting.
class FundlyApp extends ConsumerWidget {
  const FundlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseName = ref.watch(
      authIdentityProvider.select(databaseNameFor),
    );
    return MaterialApp(
      // A new database means new data: rebuild navigation from the home tabs
      // so no open screen or dialog keeps showing the previous user's records.
      key: ValueKey(databaseName),
      title: 'Fundly',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}
