import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

/// The user's colour palette and light/dark choice. Kept per device only:
/// never synced and not part of backups.
@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.palette = AppPalette.fallback,
    this.mode = ThemeMode.system,
  });

  final AppPalette palette;
  final ThemeMode mode;

  AppearanceSettings copyWith({AppPalette? palette, ThemeMode? mode}) =>
      AppearanceSettings(
        palette: palette ?? this.palette,
        mode: mode ?? this.mode,
      );

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.palette == palette &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(palette, mode);
}

/// The name shown for a [ThemeMode] on the Profile tab.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

/// Loads and saves [AppearanceSettings] on this device.
abstract class AppearanceStore {
  AppearanceSettings load();

  Future<void> save(AppearanceSettings settings);
}

/// Keeps the settings for this run only. The default, used by tests and
/// when the device's preferences are unavailable.
class InMemoryAppearanceStore implements AppearanceStore {
  InMemoryAppearanceStore([this._settings = const AppearanceSettings()]);

  AppearanceSettings _settings;

  @override
  AppearanceSettings load() => _settings;

  @override
  Future<void> save(AppearanceSettings settings) async => _settings = settings;
}

/// Keeps the settings in the app's preferences on the device. Unknown saved
/// values (from a later app version, say) fall back to the defaults.
class SharedPreferencesAppearanceStore implements AppearanceStore {
  SharedPreferencesAppearanceStore(this._preferences);

  static const paletteKey = 'fundly.appearance.palette';
  static const modeKey = 'fundly.appearance.mode';

  final SharedPreferences _preferences;

  @override
  AppearanceSettings load() {
    final mode = _preferences.getString(modeKey);
    return AppearanceSettings(
      palette: AppPalette.fromName(_preferences.getString(paletteKey)),
      mode: ThemeMode.values.firstWhere(
        (value) => value.name == mode,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  @override
  Future<void> save(AppearanceSettings settings) async {
    await _preferences.setString(paletteKey, settings.palette.name);
    await _preferences.setString(modeKey, settings.mode.name);
  }
}

final appearanceStoreProvider = Provider<AppearanceStore>(
  (ref) => InMemoryAppearanceStore(),
);

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceSettings>(
      AppearanceNotifier.new,
    );

/// Applies a new palette or mode at once and saves it in the background.
class AppearanceNotifier extends Notifier<AppearanceSettings> {
  @override
  AppearanceSettings build() => ref.watch(appearanceStoreProvider).load();

  void setPalette(AppPalette palette) =>
      _apply(state.copyWith(palette: palette));

  void setMode(ThemeMode mode) => _apply(state.copyWith(mode: mode));

  void _apply(AppearanceSettings settings) {
    state = settings;
    ref.read(appearanceStoreProvider).save(settings);
  }
}
