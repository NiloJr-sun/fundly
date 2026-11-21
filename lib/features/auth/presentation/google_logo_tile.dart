import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';

/// Google's "G" logo on a small white tile. Google's branding guidelines
/// require the logo on a white background, so it works on any button colour.
class GoogleLogoTile extends StatelessWidget {
  const GoogleLogoTile({super.key, this.size = 26});

  /// Outer size of the tile, padding included.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(Spacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Spacing.xs),
      ),
      child: Image.asset(
        'assets/images/google_logo.png',
        // Not announced: the text beside it already says Google.
        excludeFromSemantics: true,
      ),
    );
  }
}
