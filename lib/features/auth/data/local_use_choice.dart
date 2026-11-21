import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_identity.dart';
import 'auth_repository.dart';

/// Remembers on this device that the user chose "Use without an account" on
/// the login page, so later launches open the local data directly.
abstract class LocalUseChoiceStore {
  bool get chosen;

  Future<void> save({required bool chosen});
}

/// Keeps the choice for this run only. The default, used by tests and by
/// builds without the cloud configuration (which never show the login page).
class InMemoryLocalUseChoiceStore implements LocalUseChoiceStore {
  InMemoryLocalUseChoiceStore({this.chosen = false});

  @override
  bool chosen;

  @override
  Future<void> save({required bool chosen}) async => this.chosen = chosen;
}

/// Keeps the choice in the app's preferences on the device.
class SharedPreferencesLocalUseChoiceStore implements LocalUseChoiceStore {
  SharedPreferencesLocalUseChoiceStore(this._preferences);

  static const key = 'fundly.localUseChosen';

  final SharedPreferences _preferences;

  @override
  bool get chosen => _preferences.getBool(key) ?? false;

  @override
  Future<void> save({required bool chosen}) =>
      _preferences.setBool(key, chosen);
}

final localUseChoiceStoreProvider = Provider<LocalUseChoiceStore>(
  (ref) => InMemoryLocalUseChoiceStore(),
);

/// Whether the user chose to use Fundly without an account.
///
/// Signing in clears the choice, so signing out (or a revoked session) shows
/// the login page again instead of silently reopening the local data.
final localUseChosenProvider = NotifierProvider<LocalUseChosenNotifier, bool>(
  LocalUseChosenNotifier.new,
);

class LocalUseChosenNotifier extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(localUseChoiceStoreProvider);
    ref.listen(authIdentityProvider, (_, identity) {
      if (identity is SignedIn && state) _save(store, chosen: false);
    });
    if (!store.chosen) return false;
    if (ref.read(authIdentityProvider) is SignedIn) {
      // A session restored at launch also clears an old choice.
      store.save(chosen: false);
      return false;
    }
    return true;
  }

  /// "Use without an account" on the login page.
  void choose() => _save(ref.read(localUseChoiceStoreProvider), chosen: true);

  void _save(LocalUseChoiceStore store, {required bool chosen}) {
    state = chosen;
    store.save(chosen: chosen);
  }
}
