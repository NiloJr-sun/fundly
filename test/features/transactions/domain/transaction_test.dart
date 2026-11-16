import 'package:flutter_test/flutter_test.dart';

import 'transaction_fixtures.dart';

void main() {
  test('drafts are equal when all fields match', () {
    expect(spending(), spending());
    expect(spending().hashCode, spending().hashCode);
    expect(spending(amount: 1), isNot(spending(amount: 2)));
  });

  test('a saved transaction is not equal to its draft', () {
    final draft = spending();

    expect(saved(draft), isNot(draft));
    expect(draft, isNot(saved(draft)));
    expect(saved(draft), saved(draft));
  });
}
