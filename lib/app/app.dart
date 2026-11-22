import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_name.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/local_use_choice.dart';
import '../features/auth/domain/auth_identity.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/backup/presentation/device_data_prompt.dart';
import 'home_shell.dart';
import 'theme/app_theme.dart';

/// Root widget of the Fundly app.
///
/// Follows the device's light or dark setting. While signed out in a build
/// that can sign in, the login page comes first unless the user chose to use
/// Fundly without an account.
class FundlyApp extends ConsumerWidget {
  const FundlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseName = ref.watch(
      authIdentityProvider.select(databaseNameFor),
    );
    // Watched unconditionally so the choice stays live and is cleared when a
    // user signs in.
    final localUseChosen = ref.watch(localUseChosenProvider);
    final showLogin =
        ref.watch(authRepositoryProvider).canSignIn &&
        ref.watch(authIdentityProvider) is SignedOut &&
        !localUseChosen;
    return MaterialApp(
      // A new database means new data: rebuild navigation from the home tabs
      // so no open screen or dialog keeps showing the previous user's records.
      key: ValueKey(databaseName),
      title: 'Fundly',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: showLogin
          ? const LoginScreen()
          : const DeviceDataPrompt(child: HomeShell()),
    );
  }
}
