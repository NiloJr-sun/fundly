import 'package:flutter/material.dart';

/// The colour palettes the user can pick on the Profile tab. Saved by
/// [name], so renaming a value would reset users to the default.
///
/// Each palette has a light and a dark [PaletteShade]. Destructive actions
/// keep `colorScheme.error`, which no palette changes; money going out uses
/// the palette's [PaletteShade.expense] instead.
enum AppPalette {
  /// The original look, unchanged.
  classicTeal(
    'Classic Teal',
    seed: Color(0xFF00796B),
    light: PaletteShade(
      surface: Color(0xFFF4F7F6),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFEFF5F2),
      surfaceContainer: Color(0xFFE9F0ED),
      surfaceContainerHigh: Color(0xFFE2EBE7),
      surfaceContainerHighest: Color(0xFFDAE5E0),
      outlineVariant: Color(0xFFCDDAD4),
      positive: Color(0xFF388E3C),
      // The seed scheme's error colour, which expense amounts used before
      // palettes existed.
      expense: Color(0xFFBA1A1A),
      warning: Color(0xFF8D6E00),
      backdrop: _mintBackdrop,
    ),
    dark: PaletteShade(
      surface: Color(0xFF101714),
      surfaceContainerLowest: Color(0xFF0B120F),
      surfaceContainerLow: Color(0xFF17211D),
      surfaceContainer: Color(0xFF1B2722),
      surfaceContainerHigh: Color(0xFF24312B),
      surfaceContainerHighest: Color(0xFF2F3D35),
      outlineVariant: Color(0xFF33473D),
      positive: Color(0xFF81C784),
      expense: Color(0xFFFFB4AB),
      warning: Color(0xFFFFD54F),
      backdrop: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF064E4B), Color(0xFF14362E), Color(0xFF101714)],
        stops: [0, 0.42, 1],
      ),
    ),
  ),

  oceanCalm(
    'Ocean Calm',
    seed: Color(0xFF3B6EA5),
    light: PaletteShade(
      surface: Color(0xFFF4F8FC),
      surfaceContainerLowest: Color(0xFFFDFEFF),
      surfaceContainerLow: Color(0xFFF1F3F6),
      surfaceContainer: Color(0xFFEBEEF2),
      surfaceContainerHigh: Color(0xFFE3E8ED),
      surfaceContainerHighest: Color(0xFFDBE0E6),
      outlineVariant: Color(0xFFCAD1D8),
      onSurface: Color(0xFF1F2F45),
      onSurfaceVariant: Color(0xFF66758A),
      accent: Color(0xFFF0B86E),
      positive: Color(0xFF3E9E6E),
      expense: Color(0xFFD6605A),
      warning: Color(0xFF8D6E00),
      backdrop: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDCE8F5), Color(0xFFF4F8FC)],
      ),
    ),
    dark: PaletteShade(
      surface: Color(0xFF131920),
      surfaceContainerLowest: Color(0xFF0E1318),
      surfaceContainerLow: Color(0xFF1C232C),
      surfaceContainer: Color(0xFF222A32),
      surfaceContainerHigh: Color(0xFF29313B),
      surfaceContainerHighest: Color(0xFF323C46),
      outlineVariant: Color(0xFF3D4752),
      onSurface: Color(0xFFEAEDF1),
      onSurfaceVariant: Color(0xFFAFB7C0),
      accent: Color(0xFFF0B86E),
      positive: Color(0xFF44AD78),
      expense: Color(0xFFDE7F7B),
      warning: Color(0xFFFFD54F),
      backdrop: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E2D3E), Color(0xFF19222C), Color(0xFF131920)],
        stops: [0, 0.42, 1],
      ),
    ),
  ),
  lavenderMist(
    'Lavender Mist',
    seed: Color(0xFF6E5FA8),
    light: PaletteShade(
      surface: Color(0xFFF7F5FB),
      surfaceContainerLowest: Color(0xFFFEFDFF),
      surfaceContainerLow: Color(0xFFF2F1F6),
      surfaceContainer: Color(0xFFECEBF2),
      surfaceContainerHigh: Color(0xFFE5E3ED),
      surfaceContainerHighest: Color(0xFFDDDBE6),
      outlineVariant: Color(0xFFCDCAD8),
      onSurface: Color(0xFF2D2840),
      onSurfaceVariant: Color(0xFF716B85),
      accent: Color(0xFFF2A97C),
      positive: Color(0xFF4E9E78),
      expense: Color(0xFFD4636B),
      warning: Color(0xFF8D6E00),
      backdrop: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE7E2F4), Color(0xFFF7F5FB)],
      ),
    ),
    dark: PaletteShade(
      surface: Color(0xFF161320),
      surfaceContainerLowest: Color(0xFF100E18),
      surfaceContainerLow: Color(0xFF1F1C2C),
      surfaceContainer: Color(0xFF252232),
      surfaceContainerHigh: Color(0xFF2C293B),
      surfaceContainerHighest: Color(0xFF363246),
      outlineVariant: Color(0xFF413D52),
      onSurface: Color(0xFFEBEAF1),
      onSurfaceVariant: Color(0xFFB3AFC0),
      accent: Color(0xFFF2A97C),
      positive: Color(0xFF51A57D),
      expense: Color(0xFFDA777E),
      warning: Color(0xFFFFD54F),
      backdrop: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF241E3E), Color(0xFF1D192C), Color(0xFF161320)],
        stops: [0, 0.42, 1],
      ),
    ),
  ),
  warmSand(
    'Warm Sand',
    seed: Color(0xFF9A6B3F),
    light: PaletteShade(
      surface: Color(0xFFFBF7F2),
      surfaceContainerLowest: Color(0xFFFFFDFA),
      surfaceContainerLow: Color(0xFFF6F3F1),
      surfaceContainer: Color(0xFFF2EEEB),
      surfaceContainerHigh: Color(0xFFEDE8E3),
      surfaceContainerHighest: Color(0xFFE6E0DB),
      outlineVariant: Color(0xFFD8D1CA),
      onSurface: Color(0xFF3A2E25),
      onSurfaceVariant: Color(0xFF7C6F64),
      accent: Color(0xFF7FA88F),
      positive: Color(0xFF5E9466),
      expense: Color(0xFFC2453F),
      warning: Color(0xFF8D6E00),
      backdrop: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3E9DC), Color(0xFFFBF7F2)],
      ),
    ),
    dark: PaletteShade(
      surface: Color(0xFF201913),
      surfaceContainerLowest: Color(0xFF18130E),
      surfaceContainerLow: Color(0xFF2C231C),
      surfaceContainer: Color(0xFF322A22),
      surfaceContainerHigh: Color(0xFF3B3129),
      surfaceContainerHighest: Color(0xFF463C32),
      outlineVariant: Color(0xFF52473D),
      onSurface: Color(0xFFF1EDEA),
      onSurfaceVariant: Color(0xFFC0B7AF),
      accent: Color(0xFF7FA88F),
      positive: Color(0xFF77A97F),
      expense: Color(0xFFD88885),
      warning: Color(0xFFFFD54F),
      backdrop: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E2D1E), Color(0xFF2C2219), Color(0xFF201913)],
        stops: [0, 0.42, 1],
      ),
    ),
  ),
  slate(
    'Slate',
    seed: Color(0xFF4A5B6E),
    light: PaletteShade(
      surface: Color(0xFFF5F7F9),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF1F3F6),
      surfaceContainer: Color(0xFFEBEEF2),
      surfaceContainerHigh: Color(0xFFE3E8ED),
      surfaceContainerHighest: Color(0xFFDBE0E6),
      outlineVariant: Color(0xFFCAD1D8),
      onSurface: Color(0xFF1E252D),
      onSurfaceVariant: Color(0xFF6B7480),
      accent: Color(0xFFE8B04B),
      positive: Color(0xFF3F9A68),
      expense: Color(0xFFD95B5B),
      warning: Color(0xFF8D6E00),
      backdrop: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE4E8ED), Color(0xFFF5F7F9)],
      ),
    ),
    dark: PaletteShade(
      surface: Color(0xFF131920),
      surfaceContainerLowest: Color(0xFF0E1318),
      surfaceContainerLow: Color(0xFF1C232C),
      surfaceContainer: Color(0xFF222A32),
      surfaceContainerHigh: Color(0xFF29313B),
      surfaceContainerHighest: Color(0xFF323B46),
      outlineVariant: Color(0xFF3D4752),
      onSurface: Color(0xFFEAEDF1),
      onSurfaceVariant: Color(0xFFAFB7C0),
      accent: Color(0xFFE8B04B),
      positive: Color(0xFF46AC74),
      expense: Color(0xFFE17C7C),
      warning: Color(0xFFFFD54F),
      backdrop: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E2D3E), Color(0xFF19222C), Color(0xFF131920)],
        stops: [0, 0.42, 1],
      ),
    ),
  ),

  /// Mint, Sage, Emerald and Rose (#8EE7B7, #A7F3D0, #34D399, #F67165) on
  /// near-black surfaces; designed dark first. The light shade uses deeper
  /// greens and rose so money colours stay readable on pale surfaces.
  midnightMint(
    'Midnight Mint',
    seed: Color(0xFF34D399),
    light: PaletteShade(
      surface: Color(0xFFF3FAF6),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFEDF6F1),
      surfaceContainer: Color(0xFFE6F0EA),
      surfaceContainerHigh: Color(0xFFDEEAE3),
      surfaceContainerHighest: Color(0xFFD5E3DB),
      outlineVariant: Color(0xFFC4D6CC),
      onSurface: Color(0xFF13201A),
      onSurfaceVariant: Color(0xFF4F6158),
      accent: Color(0xFFA7F3D0),
      positive: Color(0xFF17734B),
      expense: Color(0xFFB33A31),
      warning: Color(0xFF8D6E00),
      backdrop: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCDF5E2), Color(0xFFF3FAF6)],
      ),
    ),
    dark: PaletteShade(
      surface: Color(0xFF0F1412),
      surfaceContainerLowest: Color(0xFF0A0E0C),
      surfaceContainerLow: Color(0xFF161C19),
      surfaceContainer: Color(0xFF1B221F),
      surfaceContainerHigh: Color(0xFF222A26),
      surfaceContainerHighest: Color(0xFF2B3430),
      outlineVariant: Color(0xFF34403A),
      onSurface: Color(0xFFE8F0EC),
      onSurfaceVariant: Color(0xFFA9B7B0),
      accent: Color(0xFFA7F3D0),
      positive: Color(0xFF8EE7B7),
      expense: Color(0xFFF67165),
      warning: Color(0xFFFFD54F),
      backdrop: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF12352A), Color(0xFF132520), Color(0xFF0F1412)],
        stops: [0, 0.42, 1],
      ),
    ),
  );

  const AppPalette(
    this.label, {
    required this.seed,
    required this.light,
    required this.dark,
  });

  /// The name shown to the user.
  final String label;

  /// Seeds the Material colour scheme; the primary colour is derived from it.
  final Color seed;

  final PaletteShade light;
  final PaletteShade dark;

  static const AppPalette fallback = classicTeal;

  PaletteShade shade(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The palette saved as [name], or [fallback] if none or unknown.
  static AppPalette fromName(String? name) {
    for (final palette in values) {
      if (palette.name == name) return palette;
    }
    return fallback;
  }
}

/// One brightness of a palette: surfaces, text and money colours. Fields
/// left null keep the Material colour scheme's value from the seed.
@immutable
class PaletteShade {
  const PaletteShade({
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outlineVariant,
    required this.positive,
    required this.expense,
    required this.warning,
    required this.backdrop,
    this.onSurface,
    this.onSurfaceVariant,
    this.accent,
  });

  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outlineVariant;

  /// Main and secondary text.
  final Color? onSurface;
  final Color? onSurfaceVariant;

  /// Becomes the scheme's tertiary colour (tertiary containers are tinted
  /// with it). Accents are light, so text and icons on an accent fill use
  /// the palette's light-mode [onSurface] (its dark text colour).
  final Color? accent;

  /// Money in and positive balances.
  final Color positive;

  /// Money out: overspent and over-assigned amounts.
  final Color expense;

  final Color warning;
  final LinearGradient backdrop;
}

const _mintBackdrop = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF88D3CA), Color(0xFFB9EDD9), Color(0xFFF4F7F6)],
  stops: [0, 0.42, 1],
);
