import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_name.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/local_use_choice.dart';
import '../features/auth/domain/auth_identity.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/backup/presentation/device_data_prompt.dart';
import '../features/spaces/data/active_space.dart';
import '../features/spaces/data/space_removals.dart';
import '../features/spaces/presentation/join_space.dart';
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
    final activeSpace = ref.watch(activeSpaceIdProvider);
    // Kept running while the app is open: it handles spaces that leave this
    // device (shared spaces C3). Listened to, so its changes rebuild nothing
    // here.
    ref.listen(spaceRemovalsProvider, (_, _) {});
    // Watched unconditionally so the choice stays live and is cleared when a
    // user signs in.
    final localUseChosen = ref.watch(localUseChosenProvider);
    final showLogin =
        ref.watch(authRepositoryProvider).canSignIn &&
        ref.watch(authIdentityProvider) is SignedOut &&
        !localUseChosen;
    return MaterialApp(
      // A new database or space means new data: rebuild navigation from the
      // home tabs so no open screen or dialog keeps showing the previous
      // user's or space's records.
      key: ValueKey((databaseName, activeSpace)),
      title: 'Fundly',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: showLogin
          ? const LoginScreen()
          : const DeviceDataPrompt(
              child: PendingInviteHandler(child: HomeShell()),
            ),
    );
  }
}
