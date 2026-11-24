import '../data/sharing_service.dart';

/// What a failed invite, member or space action says, in plain words.
String sharingProblemMessage(SharingProblem problem) => switch (problem) {
  SharingProblem.offline =>
    "Couldn't reach the server. Check your connection and try again.",
  SharingProblem.notMember => "You're no longer a member of this space.",
  SharingProblem.ownerOnly => 'Only an owner of this space can do this.',
  SharingProblem.personalSpace =>
    'Your Personal space is never shared, left or deleted.',
  SharingProblem.invalidEmail => 'Enter a valid email.',
  SharingProblem.alreadyMember => 'That email already belongs to this space.',
  SharingProblem.memberLimitReached =>
    'This space already has 10 members, the most allowed.',
  SharingProblem.inviteLimitReached =>
    'This space already has 20 pending invites. Revoke one first.',
  SharingProblem.inviteUnavailable =>
    'This invite no longer works: it was used, declined, revoked or has '
        'expired. Ask for a new link.',
  SharingProblem.inviteOtherEmail =>
    'This invite is for another email. Sign in with the email it was sent '
        'to, or ask for a new link.',
  SharingProblem.memberNotFound => 'That person is no longer a member.',
  SharingProblem.lastOwner =>
    'A space needs an owner. Make someone else an owner first, or delete '
        'the space.',
  SharingProblem.nameMismatch => "The name doesn't match the space's name.",
  SharingProblem.refused => "The server didn't allow this.",
};
