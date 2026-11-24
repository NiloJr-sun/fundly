import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatting/date_formatter.dart';
import '../data/sharing_service.dart';
import '../data/space_directory.dart';
import '../domain/invite_link.dart';
import '../domain/space.dart';
import '../domain/space_invite.dart';
import 'sharing_messages.dart';
import 'space_providers.dart';

/// Asks for an email and a role, creates the invite (owners only, online
/// only), then shows its link once (shared spaces C3, Decision C3-1).
Future<void> inviteToSpace(BuildContext context, Space space) async {
  final invite = await showDialog<CreatedInvite>(
    context: context,
    builder: (_) => _InviteDialog(space: space),
  );
  if (invite != null && context.mounted) {
    await showInviteLink(context, space, invite);
  }
}

/// Shows [invite]'s link with Copy and Share. The link is not shown again:
/// the server keeps only its secret's hash.
Future<void> showInviteLink(
  BuildContext context,
  Space space,
  CreatedInvite invite,
) => showDialog<void>(
  context: context,
  builder: (_) => _InviteLinkDialog(space: space, invite: invite),
);

class _InviteDialog extends ConsumerStatefulWidget {
  const _InviteDialog({required this.space});

  final Space space;

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  final _email = TextEditingController();
  SpaceRole _role = SpaceRole.editor;
  String? _problem;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final members =
        ref.read(spaceMembersProvider(widget.space.id)).value ?? const [];
    final problem = inviteEmailProblem(
      _email.text,
      members.map((member) => member.email),
    );
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    final service = ref.read(sharingServiceProvider);
    if (service == null) {
      setState(() => _problem = 'Sharing is not available in this version');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final invite = await service.createInvite(
        spaceId: widget.space.id,
        email: normalizeInviteEmail(_email.text),
        role: _role,
      );
      if (mounted) Navigator.of(context).pop(invite);
    } on SharingException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = sharingProblemMessage(error.problem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the members are loaded by the time the email is checked.
    ref.watch(spaceMembersProvider(widget.space.id));
    return AlertDialog(
      title: Text('Invite to ${widget.space.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'You get a link to send them. Only this email can use it, '
              'once, within 7 days.',
            ),
          ),
          TextField(
            controller: _email,
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'name@example.com',
              errorText: _problem,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _busy ? null : _invite(),
          ),
          const SizedBox(height: 16),
          SegmentedButton<SpaceRole>(
            segments: [
              for (final role in inviteRoles)
                ButtonSegment(value: role, label: Text(roleLabel(role))),
            ],
            selected: {_role},
            onSelectionChanged: _busy
                ? null
                : (selected) => setState(() => _role = selected.single),
          ),
          const SizedBox(height: 8),
          Text(
            _role == SpaceRole.editor
                ? 'Editors add and change records.'
                : 'Viewers only see records.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _invite,
          child: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create link'),
        ),
      ],
    );
  }
}

class _InviteLinkDialog extends StatelessWidget {
  const _InviteLinkDialog({required this.space, required this.invite});

  final Space space;
  final CreatedInvite invite;

  String get _link => inviteLinkFor(invite.secret);

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join ${space.name} on Fundly: $_link',
        subject: 'Join ${space.name} on Fundly',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Invite link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send this link to ${invite.email}. It works once, as '
            '${roleLabel(invite.role)}, until '
            '${DateFormatter.localDate(invite.expiresAt)}.',
          ),
          const SizedBox(height: 12),
          SelectableText(
            _link,
            key: const Key('invite-link'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            "This link isn't shown again. If it's lost, create a new one "
            'from Members.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
        TextButton(onPressed: () => _copy(context), child: const Text('Copy')),
        FilledButton.icon(
          onPressed: () => _share(context),
          icon: const Icon(Icons.ios_share),
          label: const Text('Share'),
        ),
      ],
    );
  }
}
