import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/auth/domain/greeting.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 11, 22, hour, minute);

  test('morning from 05:00 until noon', () {
    expect(greetingFor(at(5)), 'Good morning');
    expect(greetingFor(at(11, 59)), 'Good morning');
  });

  test('afternoon from noon until 18:00', () {
    expect(greetingFor(at(12)), 'Good afternoon');
    expect(greetingFor(at(17, 59)), 'Good afternoon');
  });

  test('evening from 18:00 until 05:00', () {
    expect(greetingFor(at(18)), 'Good evening');
    expect(greetingFor(at(0)), 'Good evening');
    expect(greetingFor(at(4, 59)), 'Good evening');
  });

  test('the first name is the first word of the profile name', () {
    SignedIn user(String name) =>
        SignedIn(userId: 'id', email: 'a@test.com', name: name);
    expect(user('Nilo Castillano').firstName, 'Nilo');
    expect(user('  Nilo  ').firstName, 'Nilo');
    expect(user('Nilo').firstName, 'Nilo');
    expect(user('').firstName, '');
  });
}
