import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/active_space.dart';
import '../data/invite_page.dart';
import '../data/sharing_service.dart';
import '../domain/invite_link.dart';
import '../domain/space.dart';
import '../domain/space_invite.dart';
import 'sharing_messages.dart';
import 'space_providers.dart';

/// Asks for a pasted invite link (or its code), then shows the invite
/// (shared spaces C3, Decision C3-1: iOS has no universal links yet).
Future<void> joinSpace(BuildContext context) async {
  final secret = await showDialog<String>(
    context: context,
    builder: (_) => const _PasteInviteDialog(),
  );
  if (secret != null && context.mounted) await openInvite(context, secret);
}

/// Shows what the invite [secret] offers, with Accept and Decline. Only the
/// email it names sees the space; anyone else is told nothing about it.
Future<void> openInvite(BuildContext context, String secret) =>
    showDialog<void>(
      context: context,
      builder: (_) => _InvitePreviewDialog(secret: secret),
    );

/// The invite secret this web page was opened with (`/join#<secret>`), set in
/// `main.dart`; null on native apps and on any other page.
final initialInviteSecretProvider = Provider<String?>((ref) => null);

/// The invite still to show: the page's, until [PendingInvite.take].
final pendingInviteProvider = NotifierProvider<PendingInvite, String?>(
  PendingInvite.new,
);

class PendingInvite extends Notifier<String?> {
  @override
  String? build() => ref.read(initialInviteSecretProvider);

  /// The secret, once: later calls (and reloads of the tab) get null.
  String? take() {
    final secret = state;
    state = null;
    forgetPendingInviteSecret();
    return secret;
  }
}

/// Shows the invite the web app was opened with, once the user is signed
/// in. Signed out, it says that signing in comes first and keeps the invite.
class PendingInviteHandler extends ConsumerStatefulWidget {
  const PendingInviteHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PendingInviteHandler> createState() =>
      _PendingInviteHandlerState();
}

class _PendingInviteHandlerState extends ConsumerState<PendingInviteHandler> {
  bool _toldToSignIn = false;

  void _check() {
    if (ref.read(pendingInviteProvider) == null) return;
    if (ref.read(authIdentityProvider) is SignedOut) {
      if (_toldToSignIn) return;
      _toldToSignIn = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have an invite to a space. Sign in from Profile with the '
            'email it was sent to, and it opens.',
          ),
        ),
      );
      return;
    }
    final secret = ref.read(pendingInviteProvider.notifier).take();
    if (secret != null) openInvite(context, secret);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pendingInviteProvider);
    ref.watch(authIdentityProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
    return widget.child;
  }
}

class _PasteInviteDialog extends StatefulWidget {
  const _PasteInviteDialog();

  @override
  State<_PasteInviteDialog> createState() => _PasteInviteDialogState();
}

class _PasteInviteDialogState extends State<_PasteInviteDialog> {
  final _text = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _continue() {
    final secret = inviteSecretFromText(_text.text);
    if (secret == null) {
      setState(() => _problem = 'Paste the invite link you were sent');
      return;
    }
    Navigator.of(context).pop(secret);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a space'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Paste the invite link someone sent you. The whole message '
              'is fine.',
            ),
          ),
          TextField(
            controller: _text,
            autofocus: true,
            autocorrect: false,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Invite link',
              errorText: _problem,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _continue, child: const Text('Continue')),
      ],
    );
  }
}

class _InvitePreviewDialog extends ConsumerStatefulWidget {
  const _InvitePreviewDialog({required this.secret});

  final String secret;

  @override
  ConsumerState<_InvitePreviewDialog> createState() =>
      _InvitePreviewDialogState();
}

class _InvitePreviewDialogState extends ConsumerState<_InvitePreviewDialog> {
  InvitePreview? _preview;
  String? _problem;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  SharingService? get _service => ref.read(sharingServiceProvider);

  Future<void> _load() async {
    final service = _service;
    if (service == null) {
      _fail('Sharing is not available in this version');
      return;
    }
    try {
      final preview = await service.previewInvite(widget.secret);
      if (mounted) {
        setState(() {
          _preview = preview;
          _busy = false;
        });
      }
    } on SharingException catch (error) {
      _fail(sharingProblemMessage(error.problem));
    }
  }

  void _fail(String problem) {
    if (!mounted) return;
    setState(() {
      _problem = problem;
      _busy = false;
    });
  }

  /// Closes the dialog, then shows [spaceId]. Switching spaces rebuilds the
  /// app, so the dialog goes first.
  void _openSpace(String spaceId) {
    final activeSpace = ref.read(activeSpaceIdProvider.notifier);
    Navigator.of(context).pop();
    activeSpace.select(spaceId);
  }

  Future<void> _accept() async {
    final service = _service;
    if (service == null) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final joined = await service.acceptInvite(widget.secret);
      if (mounted) _openSpace(joined.spaceId);
    } on SharingException catch (error) {
      _fail(sharingProblemMessage(error.problem));
    }
  }

  Future<void> _decline() async {
    final service = _service;
    if (service == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await service.declineInvite(widget.secret);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Invite declined.')));
    } on SharingException catch (error) {
      _fail(sharingProblemMessage(error.problem));
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final problem = _problem;
    final theme = Theme.of(context);
    final Widget content;
    if (preview == null) {
      content = problem == null
          ? const Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Checking the invite…'),
              ],
            )
          : Text(problem);
    } else {
      final inviter = preview.inviterLabel;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.alreadyMember
                ? "You're already a member of ${preview.spaceName}."
                : '${inviter ?? 'Someone'} invited you to '
                      '${preview.spaceName} as '
                      '${roleLabel(preview.role)}.',
          ),
          if (!preview.alreadyMember) ...[
            const SizedBox(height: 8),
            Text(
              'You will see its accounts, transactions and plans'
              '${preview.role == SpaceRole.viewer ? '' : ', and can change them'}'
              '. Members see your name and email. Expires '
              '${DateFormatter.localDate(preview.expiresAt)}.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (problem != null) ...[
            const SizedBox(height: 12),
            Text(problem, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      );
    }
    return AlertDialog(
      title: Text(preview == null ? 'Invite' : 'Join ${preview.spaceName}?'),
      content: content,
      actions: [
        if (preview == null || preview.alreadyMember)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        if (preview != null && preview.alreadyMember)
          FilledButton(
            onPressed: () => _openSpace(preview.spaceId),
            child: const Text('Open'),
          ),
        if (preview != null && !preview.alreadyMember) ...[
          TextButton(
            onPressed: _busy ? null : _decline,
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: _busy ? null : _accept,
            child: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Accept'),
          ),
        ],
      ],
    );
  }
}
