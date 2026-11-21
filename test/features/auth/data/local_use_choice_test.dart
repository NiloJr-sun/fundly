import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/auth/data/local_use_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the choice is kept in preferences across launches', () async {
    SharedPreferences.setMockInitialValues({});
    final first = SharedPreferencesLocalUseChoiceStore(
      await SharedPreferences.getInstance(),
    );
    expect(first.chosen, isFalse);

    await first.save(chosen: true);
    final relaunched = SharedPreferencesLocalUseChoiceStore(
      await SharedPreferences.getInstance(),
    );
    expect(relaunched.chosen, isTrue);

    await relaunched.save(chosen: false);
    expect(relaunched.chosen, isFalse);
  });

  test('a stored choice from an earlier launch is read', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesLocalUseChoiceStore.key: true,
    });
    final store = SharedPreferencesLocalUseChoiceStore(
      await SharedPreferences.getInstance(),
    );
    expect(store.chosen, isTrue);
  });
}
