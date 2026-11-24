import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../../core/widgets/centered_message.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/sharing_service.dart';
import '../data/space_directory.dart';
import '../domain/space.dart';
import '../domain/space_invite.dart';
import '../domain/space_member.dart';
import 'invite_dialog.dart';
import 'sharing_messages.dart';
import 'space_providers.dart';

/// Who is in a space (shared spaces C3): everyone sees names, emails and
/// roles; owners change roles, remove members and manage pending invites.
/// Changes are online only (Decision C3-9).
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  /// Pending invites, read from the server (they are not synced). Null
  /// until an owner's screen first loads them.
  Future<List<SpaceInvite>>? _invites;
  bool _busy = false;

  Space? get _space {
    final spaces = ref.watch(spacesProvider).value ?? const [];
    for (final space in spaces) {
      if (space.id == widget.spaceId) return space;
    }
    return null;
  }

  Future<List<SpaceInvite>> _fetchInvites() {
    final service = ref.read(sharingServiceProvider);
    return service == null
        ? Future.value(const [])
        : service.listInvites(widget.spaceId);
  }

  void _loadInvites() {
    final invites = _fetchInvites();
    setState(() {
      _invites = invites;
    });
  }

  /// Runs an owner's change, then says what happened or why it did not.
  Future<void> _change(
    Future<void> Function(SharingService service) call, {
    String? done,
    bool reloadInvites = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(sharingServiceProvider);
    if (service == null) return;
    setState(() => _busy = true);
    try {
      await call(service);
      if (done != null) {
        messenger.showSnackBar(SnackBar(content: Text(done)));
      }
    } on SharingException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(sharingProblemMessage(error.problem))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (reloadInvites) _loadInvites();
      }
    }
  }

  Future<void> _remove(SpaceMember member, Space space) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.label}?'),
        content: Text(
          'They no longer see ${space.name}, and it leaves their devices. '
          'Changes they have not sent yet are refused.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _change(
      (service) =>
          service.removeMember(spaceId: space.id, userId: member.userId),
      done: '${member.label} was removed.',
    );
  }

  Future<void> _newLink(SpaceInvite invite, Space space) async {
    final service = ref.read(sharingServiceProvider);
    if (service == null) return;
    setState(() => _busy = true);
    try {
      // A new invite to the same email replaces the pending one.
      final created = await service.createInvite(
        spaceId: space.id,
        email: invite.email,
        role: invite.role,
      );
      if (!mounted) return;
      _loadInvites();
      setState(() => _busy = false);
      await showInviteLink(context, space, created);
    } on SharingException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sharingProblemMessage(error.problem))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = _space;
    if (space == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: const CenteredMessage('This space is no longer on this device.'),
      );
    }
    final isOwner = space.role == SpaceRole.owner;
    if (isOwner) _invites ??= _fetchInvites();
    final userId = switch (ref.watch(authIdentityProvider)) {
      SignedIn(:final userId) => userId,
      SignedOut() => null,
    };
    final members = ref.watch(spaceMembersProvider(space.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Members of ${space.name}'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: _busy
                  ? null
                  : () async {
                      await inviteToSpace(context, space);
                      if (mounted) _loadInvites();
                    },
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Invite'),
            )
          : null,
      body: switch (members) {
        AsyncData(value: final list) => ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final member in list)
              _MemberTile(
                member: member,
                isYou: member.userId == userId,
                canManage: isOwner && member.userId != userId && !_busy,
                onRole: (role) => _change(
                  (service) => service.setMemberRole(
                    spaceId: space.id,
                    userId: member.userId,
                    role: role,
                  ),
                  done: '${member.label} is now ${roleLabel(role)}.',
                ),
                onRemove: () => _remove(member, space),
              ),
            if (isOwner)
              _PendingInvites(
                invites: _invites,
                busy: _busy,
                onNewLink: (invite) => _newLink(invite, space),
                onRevoke: (invite) => _change(
                  (service) => service.revokeInvite(invite.id),
                  done: 'Invite to ${invite.email} revoked.',
                  reloadInvites: true,
                ),
              ),
          ],
        ),
        AsyncError() => const CenteredMessage('Members could not be loaded.'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

enum _MemberAction { owner, editor, viewer, remove }

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isYou,
    required this.canManage,
    required this.onRole,
    required this.onRemove,
  });

  final SpaceMember member;
  final bool isYou;
  final bool canManage;
  final ValueChanged<SpaceRole> onRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final email = member.email;
    final details = [
      roleLabel(member.role),
      if (email != null && email != member.label) email,
    ];
    return ListTile(
      key: ValueKey('member-${member.userId}'),
      leading: const Icon(Icons.person_outline),
      title: Text(isYou ? '${member.label} (you)' : member.label),
      subtitle: Text(details.join(' · ')),
      trailing: canManage
          ? PopupMenuButton<_MemberAction>(
              tooltip: 'Manage ${member.label}',
              onSelected: (action) => switch (action) {
                _MemberAction.owner => onRole(SpaceRole.owner),
                _MemberAction.editor => onRole(SpaceRole.editor),
                _MemberAction.viewer => onRole(SpaceRole.viewer),
                _MemberAction.remove => onRemove(),
              },
              itemBuilder: (_) => [
                for (final (action, role) in [
                  (_MemberAction.owner, SpaceRole.owner),
                  (_MemberAction.editor, SpaceRole.editor),
                  (_MemberAction.viewer, SpaceRole.viewer),
                ])
                  if (member.role != role)
                    PopupMenuItem(
                      value: action,
                      child: Text('Make ${roleLabel(role).toLowerCase()}'),
                    ),
                const PopupMenuItem(
                  value: _MemberAction.remove,
                  child: Text('Remove from space'),
                ),
              ],
            )
          : null,
    );
  }
}

enum _InviteAction { newLink, revoke }

class _PendingInvites extends StatelessWidget {
  const _PendingInvites({
    required this.invites,
    required this.busy,
    required this.onNewLink,
    required this.onRevoke,
  });

  final Future<List<SpaceInvite>>? invites;
  final bool busy;
  final ValueChanged<SpaceInvite> onNewLink;
  final ValueChanged<SpaceInvite> onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<SpaceInvite>>(
      future: invites,
      builder: (context, snapshot) {
        final Widget body;
        if (snapshot.hasError) {
          final error = snapshot.error;
          body = ListTile(
            title: Text(
              error is SharingException
                  ? sharingProblemMessage(error.problem)
                  : 'Pending invites could not be loaded.',
            ),
          );
        } else if (!snapshot.hasData) {
          body = const ListTile(title: Text('Loading invites…'));
        } else if (snapshot.data!.isEmpty) {
          body = const ListTile(title: Text('No pending invites'));
        } else {
          body = Column(
            children: [
              for (final invite in snapshot.data!)
                ListTile(
                  key: ValueKey('invite-${invite.id}'),
                  leading: const Icon(Icons.mail_outline),
                  title: Text(invite.email),
                  subtitle: Text(
                    '${roleLabel(invite.role)} · expires '
                    '${DateFormatter.localDate(invite.expiresAt)}',
                  ),
                  trailing: busy
                      ? null
                      : PopupMenuButton<_InviteAction>(
                          tooltip: 'Manage invite to ${invite.email}',
                          onSelected: (action) => switch (action) {
                            _InviteAction.newLink => onNewLink(invite),
                            _InviteAction.revoke => onRevoke(invite),
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _InviteAction.newLink,
                              child: Text('New link'),
                            ),
                            PopupMenuItem(
                              value: _InviteAction.revoke,
                              child: Text('Revoke'),
                            ),
                          ],
                        ),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Pending invites', style: theme.textTheme.titleSmall),
            ),
            body,
          ],
        );
      },
    );
  }
}
