import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/cloud_config.dart';
import 'core/sync/dataset_import.dart';
import 'core/sync/powersync_store.dart';
import 'core/sync/synced_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/local_use_choice.dart';
import 'features/auth/data/supabase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = CloudConfig.fromEnvironment;
  final supabase = await _startSupabase(config);
  final authRepository = supabase == null
      ? null
      : SupabaseAuthRepository(supabase, config);
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
        if (supabase != null)
          importDatasetProvider.overrideWithValue(
            supabaseImportDataset(supabase),
          ),
        if (supabase != null)
          syncedStoreOpenerProvider.overrideWithValue(
            (identity) => PowerSyncStore.open(
              identity,
              client: supabase,
              powerSyncUrl: config.powerSyncUrl,
            ),
          ),
      ],
      child: const FundlyApp(),
    ),
  );
}

/// Starts Supabase when the build carries the cloud configuration, and
/// restores any saved session (offline too). Without the configuration, or if
/// start-up fails, the app runs signed out with local data only.
Future<SupabaseClient?> _startSupabase(CloudConfig config) async {
  if (!config.isConfigured) return null;
  try {
    final supabase = await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    return supabase.client;
  } on Object catch (error) {
    debugPrint('Cloud sign-in unavailable: $error');
    return null;
  }
}

/// Loads the remembered "Explore as a guest" choice. If preferences are
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
