import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/cloud_config.dart';
import 'core/sync/dataset_import.dart';
import 'core/sync/powersync_store.dart';
import 'core/sync/store_files.dart';
import 'core/sync/synced_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/local_use_choice.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/backup/data/device_copy_store.dart';
import 'features/spaces/data/active_space_store.dart';
import 'features/spaces/data/device_space_stores.dart';
import 'features/spaces/data/invite_page.dart';
import 'features/spaces/data/sharing_service.dart';
import 'features/spaces/data/space_removals.dart';
import 'features/spaces/data/space_service.dart';
import 'features/spaces/presentation/join_space.dart';

Future<void> main() async {
  // First, before anything reads the address: an invite link's secret moves
  // out of the address bar (web only; shared spaces C3).
  final inviteSecret = takeInviteSecretFromPage();
  WidgetsFlutterBinding.ensureInitialized();
  const config = CloudConfig.fromEnvironment;
  final supabase = await _startSupabase(config);
  final authRepository = supabase == null
      ? null
      : SupabaseAuthRepository(supabase, config);
  final preferences = authRepository == null ? null : await _loadPreferences();
  runApp(
    ProviderScope(
      overrides: [
        initialInviteSecretProvider.overrideWithValue(inviteSecret),
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
        if (preferences != null) ...[
          localUseChoiceStoreProvider.overrideWithValue(
            SharedPreferencesLocalUseChoiceStore(preferences),
          ),
          activeSpaceStoreProvider.overrideWithValue(
            SharedPreferencesActiveSpaceStore(preferences),
          ),
          deviceCopyStoreProvider.overrideWithValue(
            SharedPreferencesDeviceCopyStore(preferences),
          ),
          deviceSpaceStoresProvider.overrideWithValue(
            SharedPreferencesDeviceSpaceStores(preferences),
          ),
        ],
        if (supabase != null)
          importDatasetProvider.overrideWithValue(
            supabaseImportDataset(supabase),
          ),
        if (supabase != null)
          spaceServiceProvider.overrideWithValue(
            SupabaseSpaceService(supabase),
          ),
        if (supabase != null) ...[
          sharingServiceProvider.overrideWithValue(
            SupabaseSharingService(supabase),
          ),
          spaceStoreFilesProvider.overrideWithValue(PowerSyncStoreFiles()),
        ],
        if (supabase != null)
          syncedStoreOpenerProvider.overrideWithValue(
            (identity, spaceId) => PowerSyncStore.open(
              identity,
              spaceId,
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

/// Loads the device's preferences, which keep the "Explore as a guest"
/// choice and what this device's data was copied to (cloud sync S6.2). If
/// they are unavailable, both last for this run only.
Future<SharedPreferences?> _loadPreferences() async {
  try {
    return await SharedPreferences.getInstance();
  } on Object catch (error) {
    debugPrint('Preferences unavailable for this run: $error');
    return null;
  }
}
