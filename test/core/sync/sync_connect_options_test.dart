import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/powersync_store.dart';

void main() {
  // F.2: the web worker ignores includeDefaultStreams, so the parameter is
  // what keeps Personal's records out of other spaces there.
  test('stores connect without the automatic stream, on every platform', () {
    expect(syncConnectOptions.includeDefaultStreams, isFalse);
    expect(syncConnectOptions.params, {'space_streams': true});
  });
}
