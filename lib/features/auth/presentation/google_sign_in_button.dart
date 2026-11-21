import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import 'google_logo_tile.dart';

/// Shape shared by the sign-in buttons on the login page and Profile tab.
final authButtonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
);

/// "Continue with Google" in the app's theme colour, with Google's logo on
/// its white tile; a spinner replaces the logo while [busy].
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    required this.busy,
  });

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: authButtonStyle,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Same size either way, so the label does not shift.
          SizedBox.square(
            dimension: 26,
            child: busy
                // No white tile while loading: the spinner takes the
                // button's own (disabled) text colour.
                ? Padding(
                    padding: const EdgeInsets.all(Spacing.xs),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      // A disabled FilledButton's text colour.
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.38),
                    ),
                  )
                : const GoogleLogoTile(),
          ),
          const SizedBox(width: Spacing.sm + Spacing.xs),
          // Wraps rather than overflows with large accessibility text sizes.
          const Flexible(
            child: Text('Continue with Google', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
