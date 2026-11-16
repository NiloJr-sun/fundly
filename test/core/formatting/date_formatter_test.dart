import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/formatting/date_formatter.dart';

void main() {
  test('localDate formats a medium date in local time', () {
    // Noon UTC is the same calendar day in every timezone from -11 to +11.
    final instant = DateTime.utc(2026, 11, 16, 12);

    expect(DateFormatter.localDate(instant), 'Nov 16, 2026');
  });
}
