# Shared spaces C3: sharing (plan)

Date: 2026-11-24

Status: **approved 2026-11-24** (Decisions C3-1 to C3-10, all as
recommended). **C3.1 and C3.2 done 2026-11-24**; C3.3 next. Slice C3 of
[SHARED_SPACES_PROPOSAL.md](SHARED_SPACES_PROPOSAL.md), after C2 (released as
1.3.0). The agent stops after each sub-slice and never commits or pushes;
production writes are run by the owner, and app changes reach `main` only
after the server and sync steps are live ([OPERATIONS.md](OPERATIONS.md)).

## Goal

From the proposal: **Option B, shared spaces.** An owner invites someone by
email to a space as an editor or a viewer; the invitee accepts or declines;
everyone sees who belongs to the space and their role; owners change roles
and remove members; anyone can leave; an owner can delete a space. A viewer
sees the space but cannot change it. When someone stops belonging to a space,
its data leaves their devices, and changes they had not sent yet are kept
for them to review (Decision 8). "Added by" and clearer conflict messages are
C4.

## Starting point

- **Server (C1, C2):** spaces, members with roles (owner, editor, viewer),
  membership reads, role-checked writes (`not_space_member`,
  `space_read_only`, `space_owner_only`), create and rename RPCs, at most 10
  owned spaces. No invites, no member management, no space deletion.
  `space_members` holds only ids and roles: members cannot see each other's
  names or emails (clients cannot read `auth.users`).
- **Sync:** `fundly_spaces` (the user's spaces and their members) and
  `fundly_space_data` (one space, membership-checked); losing membership
  removes the rows at the next checkpoint (proven in C0 and C2).
- **App 1.3.0:** one store per space, a remembered active space with a
  server-checked fallback to Personal, the Profile card sheet (switch,
  create, rename), per-space backup, restore and reset, refused changes per
  store. The S5.2 `canEditProvider` read-only gate was removed when uploads
  arrived; there is no edit gate today.
- **Links:** the iOS app handles no links except Google sign-in's callback;
  the web app has no routes beyond its tabs.
- C0 findings still apply: a space is ready only once listed (finding 2),
  refused uploads are logged and completed, never retried (finding 3).

## What does not change

- Financial rules inside every space; Personal stays private.
- Apps 1.2.x (Personal only) and 1.3.0: they keep working. A 1.3.0 user added
  to a shared space sees it; as a viewer their edits are refused and logged
  (no edit gate before 1.4.0). No forced update; the minimum stays 1.2.0.
- Backup format 7; the existing streams' shape (columns are added, see below).

## Proposed design

### Server

**Invites** (`space_invites`, backend only: not synced, read through RPCs):
`id`, `space_id`, `email` (lower-cased), `role` (editor or viewer),
`token_hash` (SHA-256 of a 32-byte random secret; the secret itself is never
stored), `created_by`, `created_at`, `expires_at` (7 days),
`accepted_by/at`, `declined_at`, `revoked_at`.

| RPC | Who | Does |
|---|---|---|
| `fundly_create_invite(space_id, email, role)` | owner | Returns the secret once, to build the link. Refused for Personal, for an existing member's email, over the limits |
| `fundly_list_invites(space_id)` | owner | Pending invites (email, role, expiry); never the secret |
| `fundly_revoke_invite(invite_id)` | owner | Ends it |
| `fundly_preview_invite(secret)` | signed in | Space name, inviter's name, role, expiry, **only if the signed-in email matches** the invite; otherwise a refusal that reveals nothing about the space |
| `fundly_accept_invite(secret)` / `fundly_decline_invite(secret)` | the invited email | Single use; expired, revoked or used ones are refused |
| `fundly_set_member_role(space_id, user_id, role)` | owner | owner, editor or viewer; a space keeps an owner |
| `fundly_remove_member(space_id, user_id)` | owner | Not the last owner |
| `fundly_leave_space(space_id)` | any member | Not the last owner (they promote someone or delete the space) |
| `fundly_delete_space(space_id, name)` | owner | Non-Personal only, after the typed name matches; tombstones every record, removes invites and members, then the space |

**Who is in a space:** `space_members` gains `email` and `display_name`,
copied from the member's sign-in when they join (Decision C3-3) and synced in
`fundly_spaces`, so members see each other's names and emails, nothing else
about each other. Backfilled for existing members.

**Limits** (Decision C3-5): 10 members per space (owner included), 20
pending invites per space, invites valid 7 days and single use.

**Personal is never shared or deleted** (Decision C3-2): invites, role
changes and deletion are refused for a Personal space.

### Invite links (Decision C3-1)

The owner shares a link `https://fundly-budget.vercel.app/join#<secret>`
through the system share sheet (Messages, email…); the app sends no email
(Decision 4). The secret sits after `#`, so it never reaches Vercel's logs.

- **Web:** opening the link signs the user in if needed, shows the preview
  (space, inviter, role) with Accept and Decline.
- **iOS:** the sheet gets **Join a space**, where the user pastes the link
  (or just the secret). No universal links: those need Associated Domains,
  new signing and hosting work, and can come later.

### App

- **Edit gate for viewers** (Decision C3-8): `canEditProvider` returns to
  every add, edit, delete and archive entry point (the S5.2 pattern), false
  for a viewer; screens show a "View only" note instead of opening a form.
  The server keeps refusing anyway.
- **Space sheet:** per space, **Members** (everyone can see; owners manage),
  **Invite** (owners), **Leave space**, **Delete space** (owners, typing the
  name), and **Join a space**. Member management, invites, leaving and
  deleting are online only, like creating.
- **Members screen:** names, emails and roles; owners change roles and
  remove; pending invites listed for owners with Revoke and a new link.
- **When a space leaves a device** (removed, left or deleted; Decision
  C3-6): the store stops syncing that space (the server already removes the
  rows). If the store had changes not yet uploaded, they are refused
  (`not_space_member`) and logged as today; then:
  - no unsent or refused changes: the store is deleted from the device and,
    if it was active, the app switches to Personal and says why;
  - otherwise the space stays on the device, **read-only and marked
    "Removed"** in the sheet, until the user opens it, exports or dismisses
    its refused changes, and taps "Remove from this device".
  The device keeps a list of its space stores per user, so stores of spaces
  that left while closed are found and handled the same way at start.
- **Refused changes** get plain words for the space codes ("You're no longer
  a member of this space", "View only", "Only the owner can…"); fuller
  conflict wording is C4.
- **Active space name** already shows on Spending and Plans with several
  spaces; a shared space also shows the user's role when it is not owner.

## Sub-slices

### C3.1: Server (agent, local) ✅ Done 2026-11-24

Migration (invites table and RPCs, member names, management RPCs, deletion,
limits), rollback file, docs (WRITE_API.md, a new SPACES_API.md). Tests:
pgTAP privacy matrix for every new RPC (owner, editor, viewer, non-member,
removed member, wrong email, expired, revoked, used, Personal refused),
deletion tombstones and member cascades, limits; concurrency (accept vs
revoke, two owners changing one member); local sync rehearsal with
fundly-local: an accepted member's devices get the space, a removed member's
devices lose it, a deleted space leaves every member's devices, names reach
other members.

**Result** (local only; nothing deployed):

- Migration `20261124040000_sharing.sql`: `space_invites` (hashed secrets,
  7-day single-use, email-bound), members' `email` and `display_name`
  (filled when they join, backfilled), and ten RPCs: create, list, revoke,
  preview, accept and decline invites; set role, remove, leave; delete a
  space. Membership changes take the space's write lock; every refusal is a
  `P0001` message. New [supabase/SPACES_API.md](../supabase/SPACES_API.md).
  `fundly_spaces` now also syncs members' email and display name.
- New `tests/database/sharing_test.sql`, 77 checks: invites (secret once,
  trimmed lower-case email, never listed, Personal refused, invalid email and
  role, already a member, outsider and editor refused), preview and accept
  only for the named email (another email learns nothing), single use,
  decline, replace, revoke, expiry, roles and the last owner, a viewer who
  joined cannot write, members see each other, leaving and removal (Personal,
  last owner), both limits, re-inviting, deleting (owner only, typed name,
  Personal refused, tombstones for every record). With the email check
  disabled, the tests fail.
- New `tests/concurrency/sharing_test.py`, 3 checks: an accept waiting behind
  a revoke is refused and nobody joins; two owners changing one member are
  serialized; two owners leaving at once leave one owner.
- **Sync, with the real config on local sync:** new
  `tool/sync_probe/test/c3_sharing_streams_test.dart` passes (twice): B sees
  nothing before accepting, then the space and A's name and email; B's write
  reaches A; removing B takes the space off B's store but not A's; deleting
  it takes it off both.
- Rollback `supabase/rollback/20261124_c3_rollback.sql` (removes invites and
  the sharing functions, keeps every record and membership), rehearsed by new
  `tests/migration/c3_rollback_test.py`: everything unchanged, the C2-era
  suites pass afterwards.
- Unchanged and passing: 1064 pgTAP in total, lint (after marking
  `invite_hash` STABLE), all concurrency suites, the contract, import timing,
  the backfill and all three rollback rehearsals, the isolation and stream
  checks, the probe, and the app (1192 tests).

### C3.2: App data layer (agent, local) ✅ Done 2026-11-24

Invite and member services, link and secret parsing, synced member names
(synced schema v4 with its migration test), `canEditProvider`, the device
list of space stores, the removed-space rules (delete, or keep read-only
until reviewed), store deletion on iOS and the web, refused-change words.
Tests: unit and provider tests, plus the live store test extended to removal
with an unsent change.

**Result** (local only; no UI yet, nothing deployed):

- **Synced schema v4:** `space_members` gains `email` and `display_name`.
  The upgrade marks existing member rows in `ps_updated_rows`, so the next
  applied checkpoint writes them again from PowerSync's download log
  (members downloaded by 1.3.0 had no columns for the names). Snapshot,
  steps and two migration tests (data kept; rows marked in a PowerSync
  store).
- **Services:** `SharingService` (`spaces/data/sharing_service.dart`) for
  the ten C3 RPCs, with every server code mapped to a `SharingProblem` and
  plain words for each (`sharing_messages.dart`). `watchMembers` and
  `spaceMembersProvider` read members from the active store.
- **Invite links:** `inviteLinkFor`, `inviteSecretFromText` (the link,
  the link inside a message, or the secret alone; upper case accepted) and
  `inviteSecretFromUrl` (web `/join#secret`). `inviteEmailProblem` repeats
  the server's email rule and refuses existing members.
- **Edit gate:** `canEditProvider` is back: always true signed out and in
  Personal; in another space true for owners and editors, false for viewers,
  for a Removed space and before the spaces list has downloaded. Entry
  points use it in C3.3.
- **Spaces leaving a device:** `DeviceSpaceStores` (preferences, per user)
  lists every non-Personal space seen here. `SpaceRemovals` asks the server
  which spaces the user belongs to when a listed one disappears (and at
  start), and only acts on its answer. Nothing unsent or refused: the store
  is deleted (the active one after switching to Personal and closing it,
  with a notice naming the space). Otherwise the space stays, read-only, in
  `SpaceRemovalState.removed` until `removeFromDevice`. Offline, nothing is
  decided; a failed delete is retried at the next start. This replaces
  C2's "remembered space falls back to Personal". `PowerSyncStoreFiles`
  finds, inspects (opened without connecting) and deletes closed stores:
  files on iOS, OPFS or IndexedDB on the web. `close()` now returns the
  same future when called twice, so deletion waits for it.
- **Refused changes:** plain words for `not_space_member`,
  `space_read_only` and `space_owner_only`.
- **Tests:** 1231 passing (+40), 2 skipped (the live checks). New:
  removal rules and edit gate (19, with fake stores, server and files),
  links, members, invite emails, error mapping and wording, the device list
  in preferences, the v3 to v4 migration. **Live, on local sync, passing
  twice:** A invites B through the app's service (secret once, listed
  without it, revoked invites, another email's invite reveals nothing), B
  previews and accepts (once only), B's store gets A's email and a role
  change; B queues a change offline, A removes B; the closed store reports
  1 unsent, opening it logs `not_space_member`, the space's rows leave, the
  refused change stays; deleting the store leaves no files; the space is
  deleted afterwards. `flutter analyze` clean; iOS simulator and web builds
  succeed.
- **Not yet checked:** web store deletion with a second tab open (C3.3
  review in Chrome), and that existing members' names appear after an
  upgrade from 1.3.0 on a real device.
- **Already on the web (found during F.2):** Vercel deploys every push to
  `main`, so C3.2 has been live on the web since its push, still labelled
  1.3.0 (5), against a server without C3.1. Its sharing services are not
  reachable from any screen yet. Until C3.4, every push to `main` is a web
  release: keep `main` releasable, or hold pushes. Before C3.4, the hosted
  sync config is the hotfix branch's (F.2); C3.4 deploys `main`'s, which keeps
  the F.2 condition.

### C3.3: App UI (agent; owner reviews with two accounts)

Sheet actions, Members screen, invite dialog with share, Join a space (paste
on iOS, link on the web), leave, remove and delete confirmations, "View
only" notes, "Removed" spaces. Owner review against local sync with **two
users on two devices** (simulator and Chrome): invite, accept, edit on both,
viewer blocked, remove with an unsent change, leave, delete.

### C3.4: Release 1.4.0 (owner and agent)

Backups first (dump before `db push`), migration, sync config if it changed,
hosted checks, **then** push `main` (web), then iOS; release checklist with
accounts A and B on the iPhone and Chrome: share a space, both edit, roles,
a viewer, removal with an unsent change, leave, delete.

## Decisions for the product owner

- **C3-1. Invite links.** *(Recommended)* A web link the owner shares; the
  web app opens it; in the iOS app, paste it into Join a space.
  Alternative: universal links so the link opens the iOS app directly (needs
  Associated Domains and an `apple-app-site-association` file; more setup).
- **C3-2. Personal.** *(Recommended)* Never shared, never deleted.
  Alternative: allow sharing Personal (it would then show other people's
  changes in the space apps 1.2.x also use).
- **C3-3. Who members see.** *(Recommended)* Each other's name and email, as
  signed in with Google, copied when joining. Alternative: email only, or
  name only.
- **C3-4. Owners.** *(Recommended)* Several owners allowed; an owner can make
  another member owner; the last owner cannot leave or be removed (they
  promote someone or delete the space). Alternative: exactly one owner, with
  a transfer step.
- **C3-5. Limits.** *(Recommended)* 10 members per space, 20 pending invites
  per space, 7-day single-use invites. Alternative: other numbers.
- **C3-6. A space leaving a device.** *(Recommended)* Deleted at once when
  nothing is unsent or refused; otherwise kept read-only and marked
  "Removed" until reviewed. Alternative: always delete at once (unsent
  changes are lost), or keep every removed space until removed by hand.
- **C3-7. Deleting a space.** *(Recommended)* Owners only, non-Personal,
  after typing its name, for everyone (Decision 9). Alternative: also
  require the space to be empty first.
- **C3-8. Viewers.** *(Recommended)* Bring back the edit gate (`canEditProvider`)
  with a "View only" note. Alternative: rely on the server refusing (viewers
  would see their edits refused afterwards).
- **C3-9. Managing invites.** *(Recommended)* Online only, pending invites
  read through an RPC (not synced). Alternative: sync invites to owners.
- **C3-10. Version.** *(Recommended)* 1.4.0 (6); minimum supported stays 1.2.0.

## Risks

- **Privacy, again the main one.** An invite must only ever join the email it
  names, reveal nothing to anyone else, and work once. Mitigation: hashed
  secrets, email-bound accept, the pgTAP matrix, hosted isolation checks with
  two real accounts.
- **Losing someone's work on removal.** Mitigation: Decision C3-6 keeps
  anything unsent or refused until the member reviews it; the live test
  covers removal with an unsent change.
- **A leaked link.** Only the named email can accept, and links expire,
  are single use and revocable.
- **Store deletion on the web** (OPFS/IndexedDB while another tab has the
  store open). Mitigation: same approach as the S4 preview cleanup (retried
  on the next start), tested in Chrome with two tabs.
- **More members, more conflicts.** Revision conflicts land in Refused
  changes as today; C4 makes their wording clearer.
- **Free-plan sizes.** Limits keep a household small; usage checked monthly
  (runbook).
