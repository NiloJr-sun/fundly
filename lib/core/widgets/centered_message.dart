import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';

/// A padded, centred line of text for empty, missing and error states.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
