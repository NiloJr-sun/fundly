import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type_rules.dart';
import 'package:fundly/features/accounts/presentation/account_display.dart';

void main() {
  test('built-in names match the labels shown for built-in types', () {
    expect(builtInAccountTypeNames, [
      for (final type in AccountType.values) accountTypeLabel(type),
    ]);
  });

  test('isBuiltInAccountTypeName ignores case only', () {
    expect(isBuiltInAccountTypeName('savings / cash'), isTrue);
    expect(isBuiltInAccountTypeName('LOAN'), isTrue);
    expect(isBuiltInAccountTypeName('Savings'), isFalse);
    expect(isBuiltInAccountTypeName('Credit card'), isFalse);
  });
}
