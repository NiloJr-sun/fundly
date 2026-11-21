import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/cloud_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/local_use_choice.dart';
import 'features/auth/data/supabase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authRepository = await _startCloudAuth(CloudConfig.fromEnvironment);
  final localUseChoice = authRepository == null
      ? null
      : await _loadLocalUseChoice();
  runApp(
    ProviderScope(
      overrides: [
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
        if (localUseChoice != null)
          localUseChoiceStoreProvider.overrideWithValue(localUseChoice),
      ],
      child: const FundlyApp(),
    ),
  );
}

/// Starts Supabase Auth when the build carries the cloud configuration, and
/// restores any saved session (offline too). Without the configuration, or if
/// start-up fails, the app runs signed out with local data only.
Future<AuthRepository?> _startCloudAuth(CloudConfig config) async {
  if (!config.isConfigured) return null;
  try {
    final supabase = await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    return SupabaseAuthRepository(supabase.client, config);
  } on Object catch (error) {
    debugPrint('Cloud sign-in unavailable: $error');
    return null;
  }
}

/// Loads the remembered "Use without an account" choice. If preferences are
/// unavailable, the choice lasts for this run only.
Future<LocalUseChoiceStore?> _loadLocalUseChoice() async {
  try {
    return SharedPreferencesLocalUseChoiceStore(
      await SharedPreferences.getInstance(),
    );
  } on Object catch (error) {
    debugPrint('Login choice will not be remembered: $error');
    return null;
  }
}
