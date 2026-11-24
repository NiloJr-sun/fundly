import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';

/// An upper-case heading above a group of Profile actions.
class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xs, 0, 0, Spacing.sm),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// A rounded panel of actions with dividers between them.
class ProfileActionGroup extends StatelessWidget {
  const ProfileActionGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            children[i],
          ],
        ],
      ),
    );
  }
}

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.preview,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Shown before the chevron, e.g. the selected palette's colours.
  final Widget? preview;

  /// Shows the icon and title in the error colour, for actions that delete.
  final bool destructive;

  /// Receives where the tile is on screen, for the iPad share sheet.
  final void Function(Rect? origin) onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = destructive ? colorScheme.error : colorScheme.primary;
    // Same row shape as the spaces list: a soft icon tile, then the text.
    return ListTile(
      minTileHeight: 64,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: destructive
              ? colorScheme.error.withValues(alpha: 0.10)
              : colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent),
      ),
      title: Text(
        title,
        style: destructive ? TextStyle(color: colorScheme.error) : null,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?preview,
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ],
      ),
      onTap: () => onTap(_originOf(context)),
    );
  }

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
