import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/home_shell.dart';

import 'helpers/provider_overrides.dart';

void main() {
  testWidgets('Fundly launches without a counter scaffold', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: noAccounts(), child: const FundlyApp()),
    );
    expect(find.byType(HomeShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
