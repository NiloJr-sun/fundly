import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/features/spending/presentation/summary_cards.dart';

/// The Inflow and Spending tiles take their colours from the active palette,
/// so every palette and brightness must keep their text readable (4.5:1).
void main() {
  for (final palette in AppPalette.values) {
    for (final brightness in Brightness.values) {
      testWidgets('${palette.label} ${brightness.name}: Inflow and Spending '
          'tiles read at 4.5:1', (tester) async {
        final theme = AppTheme.build(palette, brightness);
        late ({Color? fill, Color? foreground}) inflow;
        late ({Color? fill, Color? foreground}) spending;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                inflow = summaryToneColors(context, inflow: true);
                spending = summaryToneColors(context, inflow: false);
                return const SizedBox();
              },
            ),
          ),
        );
        final money = theme.extension<AppColors>()!;
        if (palette == AppPalette.midnightMint) {
          expect(inflow.foreground, money.positive, reason: 'mint text');
        }
        expect(spending.fill, money.expense, reason: 'solid money-out fill');
        for (final (name, tone) in [
          ('Inflow', inflow),
          ('Spending', spending),
        ]) {
          expect(
            contrastRatio(tone.foreground!, tone.fill!),
            greaterThanOrEqualTo(4.5),
            reason: '$name: ${tone.foreground} on ${tone.fill}',
          );
        }
      });
    }
  }

  test('readableOn picks the text colour with the higher contrast', () {
    expect(readableOn(Colors.white), isNot(Colors.white));
    expect(readableOn(Colors.black), Colors.white);
    // Midnight Mint's rose takes dark text, as in the mockup review.
    expect(readableOn(const Color(0xFFF67165)), const Color(0xFF0B120F));
  });
}
