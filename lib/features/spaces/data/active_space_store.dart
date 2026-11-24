import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per user, which space this device last showed (shared spaces
/// C2). Read synchronously, so the first store opened is already the right
/// one.
abstract class ActiveSpaceStore {
  /// The space last chosen by [userId] on this device, or null.
  String? remembered(String userId);

  Future<void> remember(String userId, String spaceId);
}

/// Keeps the choice for this run only. The default, used by tests and by
/// builds without the cloud configuration.
class InMemoryActiveSpaceStore implements ActiveSpaceStore {
  final _chosen = <String, String>{};

  @override
  String? remembered(String userId) => _chosen[userId];

  @override
  Future<void> remember(String userId, String spaceId) async =>
      _chosen[userId] = spaceId;
}

/// Keeps the choice in the app's preferences on the device. On the web the
/// preferences are shared by the browser's tabs: the last choice wins.
class SharedPreferencesActiveSpaceStore implements ActiveSpaceStore {
  SharedPreferencesActiveSpaceStore(this._preferences);

  static String keyFor(String userId) => 'fundly.activeSpace.$userId';

  final SharedPreferences _preferences;

  @override
  String? remembered(String userId) => _preferences.getString(keyFor(userId));

  @override
  Future<void> remember(String userId, String spaceId) =>
      _preferences.setString(keyFor(userId), spaceId);
}

/// Set in `main.dart` to [SharedPreferencesActiveSpaceStore].
final activeSpaceStoreProvider = Provider<ActiveSpaceStore>(
  (ref) => InMemoryActiveSpaceStore(),
);
