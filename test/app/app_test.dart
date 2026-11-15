import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';

void main() {
  testWidgets('FundlyApp launches', (tester) async {
    await tester.pumpWidget(const FundlyApp());

    expect(find.text('Fundly'), findsOneWidget);
  });
}
