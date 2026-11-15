import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/home_shell.dart';

void main() {
  testWidgets('FundlyApp launches into the home shell', (tester) async {
    await tester.pumpWidget(const FundlyApp());

    expect(find.byType(HomeShell), findsOneWidget);
  });
}
