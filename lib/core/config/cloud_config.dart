/// Public settings for the cloud services, passed at build time with
/// `--dart-define-from-file=config/cloud.json` (see
/// `config/cloud.example.json`).
///
/// Every value here is public by design: it ships inside the app. Secrets
/// (database password, Google client secret, Supabase secret key) never belong
/// here. A build without these values has no sign-in and works only locally.
class CloudConfig {
  const CloudConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
    this.powerSyncUrl = '',
  });

  /// The values given to `flutter run` or `flutter build`, or empty strings.
  static const fromEnvironment = CloudConfig(
    supabaseUrl: String.fromEnvironment('FUNDLY_SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment(
      'FUNDLY_SUPABASE_PUBLISHABLE_KEY',
    ),
    googleWebClientId: String.fromEnvironment('FUNDLY_GOOGLE_WEB_CLIENT_ID'),
    googleIosClientId: String.fromEnvironment('FUNDLY_GOOGLE_IOS_CLIENT_ID'),
    powerSyncUrl: String.fromEnvironment('FUNDLY_POWERSYNC_URL'),
  );

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// The Google OAuth Web application client, used by Supabase to check ID
  /// tokens (the "server client ID" for native sign-in).
  final String googleWebClientId;

  /// The Google OAuth iOS client for bundle ID `com.nilojr.fundly`.
  final String googleIosClientId;

  /// The PowerSync instance that streams each user's records to the device.
  final String powerSyncUrl;

  /// Whether the app can talk to Supabase at all.
  bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Whether signed-in data can be downloaded from PowerSync.
  bool get canSync => isConfigured && powerSyncUrl.isNotEmpty;
}
