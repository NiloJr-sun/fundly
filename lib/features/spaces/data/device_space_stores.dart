import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A space whose store may be on this device (shared spaces C3).
@immutable
final class DeviceSpace {
  const DeviceSpace({
    required this.spaceId,
    required this.name,
    this.removed = false,
  });

  final String spaceId;

  /// As last listed, so a space that left can still be named.
  final String name;

  /// The space left the user, but its store holds changes that never
  /// reached the server (unsent or refused): kept read-only until the user
  /// reviews them and removes it from this device (Decision C3-6).
  final bool removed;

  DeviceSpace copyWith({String? name, bool? removed}) => DeviceSpace(
    spaceId: spaceId,
    name: name ?? this.name,
    removed: removed ?? this.removed,
  );

  @override
  bool operator ==(Object other) =>
      other is DeviceSpace &&
      other.spaceId == spaceId &&
      other.name == name &&
      other.removed == removed;

  @override
  int get hashCode => Object.hash(spaceId, name, removed);
}

/// The device's list, per user, of the spaces other than Personal whose
/// stores may be on it: every space opened or listed here. A space that
/// leaves while the app is closed is found in it at the next start. Personal
/// never leaves, so it is never listed.
abstract class DeviceSpaceStores {
  /// [userId]'s spaces on this device, by id.
  Map<String, DeviceSpace> spacesOf(String userId);

  /// Adds or updates [space] for [userId].
  Future<void> save(String userId, DeviceSpace space);

  /// Forgets [spaceId] once its store is deleted from the device.
  Future<void> forget(String userId, String spaceId);
}

/// Keeps the list for this run only: tests and builds without the cloud
/// configuration.
class InMemoryDeviceSpaceStores implements DeviceSpaceStores {
  final _spaces = <String, Map<String, DeviceSpace>>{};

  @override
  Map<String, DeviceSpace> spacesOf(String userId) =>
      Map.unmodifiable(_spaces[userId] ?? const {});

  @override
  Future<void> save(String userId, DeviceSpace space) async =>
      (_spaces[userId] ??= {})[space.spaceId] = space;

  @override
  Future<void> forget(String userId, String spaceId) async =>
      _spaces[userId]?.remove(spaceId);
}

/// Keeps the list in the app's preferences, as JSON per user. On the web the
/// preferences are shared by the browser's tabs, like the stores themselves.
class SharedPreferencesDeviceSpaceStores implements DeviceSpaceStores {
  SharedPreferencesDeviceSpaceStores(this._preferences);

  static String keyFor(String userId) => 'fundly.spaceStores.$userId';

  final SharedPreferences _preferences;

  @override
  Map<String, DeviceSpace> spacesOf(String userId) {
    final text = _preferences.getString(keyFor(userId));
    if (text == null) return const {};
    try {
      final entries = jsonDecode(text) as Map<String, Object?>;
      return {
        for (final MapEntry(:key, :value) in entries.entries)
          if (value case {'name': final String name, 'removed': final bool r})
            key: DeviceSpace(spaceId: key, name: name, removed: r),
      };
    } on FormatException {
      return const {};
    }
  }

  @override
  Future<void> save(String userId, DeviceSpace space) =>
      _write(userId, {...spacesOf(userId), space.spaceId: space});

  @override
  Future<void> forget(String userId, String spaceId) =>
      _write(userId, {...spacesOf(userId)}..remove(spaceId));

  Future<void> _write(String userId, Map<String, DeviceSpace> spaces) =>
      _preferences.setString(
        keyFor(userId),
        jsonEncode({
          for (final space in spaces.values)
            space.spaceId: {'name': space.name, 'removed': space.removed},
        }),
      );
}

/// Set in `main.dart` to [SharedPreferencesDeviceSpaceStores].
final deviceSpaceStoresProvider = Provider<DeviceSpaceStores>(
  (ref) => InMemoryDeviceSpaceStores(),
);
