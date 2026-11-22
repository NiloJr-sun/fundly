import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/config/cloud_config.dart';

void main() {
  CloudConfig config({
    String url = 'https://x.supabase.co',
    String sync = '',
  }) => CloudConfig(
    supabaseUrl: url,
    supabasePublishableKey: 'sb_publishable_x',
    googleWebClientId: '',
    googleIosClientId: '',
    powerSyncUrl: sync,
  );

  const instance = 'https://i.powersync.journeyapps.com';

  test('sync needs both Supabase and the PowerSync instance', () {
    expect(config(sync: instance).canSync, isTrue);
    expect(config().canSync, isFalse);
    expect(config(url: '', sync: instance).canSync, isFalse);
  });
}
