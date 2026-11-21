import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../data/local_use_choice.dart';
import 'sign_in_actions.dart';

/// First screen while signed out in builds that can sign in.
///
/// Google is the only way to sign in; a first-time Google user gets an
/// account automatically, so there is no separate sign-up. "Use without an
/// account" opens the data on this device that is not linked to an account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _signingIn = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _signingIn = true);
    await signInWithGoogle(context, ref);
    // On success the app replaces this screen; otherwise allow a retry.
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.of(context).backdrop),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fundly',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Track your accounts, spending and monthly plans.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: Spacing.xl),
                    _GoogleButton(
                      onPressed: _signingIn ? null : _continueWithGoogle,
                      busy: _signingIn,
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextButton(
                      onPressed: _signingIn
                          ? null
                          : () => ref
                                .read(localUseChosenProvider.notifier)
                                .choose(),
                      child: const Text('Use without an account'),
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

/// "Continue with Google" in the app's theme colour. Google's branding
/// guidelines require the "G" logo on a white background, so it sits on a
/// small white tile.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, required this.busy});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Spacing.xs),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xs),
              child: SizedBox.square(
                dimension: 18,
                child: busy
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1F1F1F),
                      )
                    : Image.asset(
                        'assets/images/google_logo.png',
                        // Not announced: the button text already says Google.
                        excludeFromSemantics: true,
                      ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm + Spacing.xs),
          const Text('Continue with Google'),
        ],
      ),
    );
  }
}
