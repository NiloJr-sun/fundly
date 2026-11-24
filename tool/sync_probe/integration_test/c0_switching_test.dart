import 'package:integration_test/integration_test.dart';

import '../test/c0_switching_test.dart' as checks;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  checks.main();
}
