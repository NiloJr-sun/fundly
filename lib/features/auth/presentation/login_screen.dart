import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../data/local_use_choice.dart';
import 'animated_wallet.dart';
import 'google_logo_tile.dart';
import 'sign_in_actions.dart';

/// First screen while signed out in builds that can sign in.
///
/// Google is the only way to sign in; a first-time Google user gets an
/// account automatically, so there is no separate sign-up. "Explore as a
/// guest" opens the data on this device that is not linked to an account.
///
/// On open, the wallet animates in and the text fades in underneath; with
/// Reduce Motion everything is shown at once and stays still.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _textIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.62, 0.92, curve: Curves.easeOut),
  );

  bool _signingIn = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _signingIn = true);
    await signInWithGoogle(context, ref);
    // On success the app replaces this screen; otherwise allow a retry.
    if (mounted) setState(() => _signingIn = false);
  }

  void _exploreAsGuest() => ref.read(localUseChosenProvider.notifier).choose();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.of(context).backdrop),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: AnimatedWallet(
                        intro: _intro,
                        animate: !_reduceMotion,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _FadeUp(animation: _textIn, child: const _Headline()),
                    const SizedBox(height: Spacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: Spacing.lg),
                    _GoogleButton(
                      onPressed: _signingIn ? null : _continueWithGoogle,
                      busy: _signingIn,
                    ),
                    const SizedBox(height: Spacing.md),
                    FilledButton.tonalIcon(
                      onPressed: _signingIn ? null : _exploreAsGuest,
                      style: _buttonStyle,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Explore as a guest'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared shape for the two login buttons.
final _buttonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
);

/// Fades its child in while sliding it up slightly.
class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// "Fundly", the tagline and what the app does.
class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Fundly',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Your money, your way.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).positive,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'A simpler way to manage your money, plan ahead, and reach your '
          'goals.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, required this.busy});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: _buttonStyle,
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
