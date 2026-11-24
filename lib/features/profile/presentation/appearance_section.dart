import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/appearance_settings.dart';
import '../../../app/theme/spacing.dart';
import 'profile_tiles.dart';

/// The Appearance section of the Profile tab: the colour palette and the
/// light/dark mode, each picked in a bottom sheet and applied at once.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionLabel('Appearance'),
        ProfileActionGroup(
          children: [
            ProfileActionTile(
              icon: Icons.palette_outlined,
              title: 'Color theme',
              subtitle: appearance.palette.label,
              preview: Padding(
                padding: const EdgeInsets.only(right: Spacing.xs),
                child: PaletteDots(
                  colors: paletteSwatches(appearance.palette, brightness),
                ),
              ),
              onTap: (_) => _pickPalette(context, ref, appearance.palette),
            ),
            ProfileActionTile(
              icon: Icons.brightness_6_outlined,
              title: 'Appearance mode',
              subtitle: themeModeLabel(appearance.mode),
              onTap: (_) => _pickMode(context, ref, appearance.mode),
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _pickPalette(
    BuildContext context,
    WidgetRef ref,
    AppPalette selected,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final brightness = Theme.of(sheetContext).brightness;
      return _Sheet(
        title: 'Color theme',
        children: [
          for (final palette in AppPalette.values)
            _Option(
              label: palette.label,
              selected: palette == selected,
              swatches: paletteSwatches(palette, brightness),
              onTap: () {
                ref.read(appearanceProvider.notifier).setPalette(palette);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      );
    },
  );

  static Future<void> _pickMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode selected,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _Sheet(
      title: 'Appearance mode',
      children: [
        for (final mode in ThemeMode.values)
          _Option(
            label: themeModeLabel(mode),
            selected: mode == selected,
            onTap: () {
              ref.read(appearanceProvider.notifier).setMode(mode);
              Navigator.of(sheetContext).pop();
            },
          ),
      ],
    ),
  );
}

/// A palette's primary, accent, income and expense colours in [brightness].
List<Color> paletteSwatches(AppPalette palette, Brightness brightness) {
  final theme = AppTheme.build(palette, brightness);
  final money = theme.extension<AppColors>()!;
  return [
    theme.colorScheme.primary,
    theme.colorScheme.tertiary,
    money.positive,
    money.expense,
  ];
}

/// Small overlapping colour dots, ringed in the panel colour.
class PaletteDots extends StatelessWidget {
  const PaletteDots({super.key, required this.colors, this.size = 14});

  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).dialogTheme.backgroundColor;
    final step = size * 0.6;
    return SizedBox(
      width: size + step * (colors.length - 1) + 4,
      height: size + 4,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: step * i,
              child: Container(
                width: size + 4,
                height: size + 4,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: ring == null
                      ? null
                      : Border.all(color: ring, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Scrolls when the options do not fit (small screens, large text).
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.sm,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.swatches,
  });

  final String label;
  final bool selected;
  final List<Color>? swatches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final swatches = this.swatches;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      selected: selected,
      title: Text(label),
      subtitle: swatches == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Row(
                children: [
                  for (final color in swatches)
                    Padding(
                      padding: const EdgeInsets.only(right: Spacing.sm),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      trailing: selected
          ? Icon(Icons.check, color: colors.primary)
          : const SizedBox(width: 24),
      onTap: onTap,
    );
  }
}
