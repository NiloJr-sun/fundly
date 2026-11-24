import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/app/theme/appearance_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesAppearanceStore', () {
    test('defaults to Classic Teal and the device setting', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesAppearanceStore(
        await SharedPreferences.getInstance(),
      );

      expect(store.load(), const AppearanceSettings());
      expect(store.load().palette, AppPalette.classicTeal);
      expect(store.load().mode, ThemeMode.system);
    });

    test('saves and loads the palette and mode', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const settings = AppearanceSettings(
        palette: AppPalette.warmSand,
        mode: ThemeMode.dark,
      );

      await SharedPreferencesAppearanceStore(preferences).save(settings);

      expect(SharedPreferencesAppearanceStore(preferences).load(), settings);
    });

    test('unknown saved values fall back to the defaults', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppearanceStore.paletteKey: 'neonPink',
        SharedPreferencesAppearanceStore.modeKey: 'sepia',
      });
      final store = SharedPreferencesAppearanceStore(
        await SharedPreferences.getInstance(),
      );

      expect(store.load(), const AppearanceSettings());
    });
  });

  test('the notifier applies a choice at once and saves it', () async {
    final store = InMemoryAppearanceStore();
    final container = ProviderContainer(
      overrides: [appearanceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container
        .read(appearanceProvider.notifier)
        .setPalette(AppPalette.oceanCalm);
    container.read(appearanceProvider.notifier).setMode(ThemeMode.light);

    const expected = AppearanceSettings(
      palette: AppPalette.oceanCalm,
      mode: ThemeMode.light,
    );
    expect(container.read(appearanceProvider), expected);
    expect(store.load(), expected);
  });
}
