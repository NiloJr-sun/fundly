import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/cloud_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authRepository = await _startCloudAuth(CloudConfig.fromEnvironment);
  runApp(
    ProviderScope(
      overrides: [
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
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
