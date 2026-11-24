# Shared spaces and collaborators (proposal)

Date: 2026-11-22

Status: **approved 2026-11-22** (scope change and Decisions 1–10, all as
recommended). Recorded in CLAUDE.md §6 and §11. **C0 done 2026-11-24: go**
([findings](SHARED_SPACES_C0_FINDINGS.md)); **C1 deployed 2026-11-24**
([plan and results](SHARED_SPACES_C1_PLAN.md)); C2 is next to plan. Each slice is
planned in detail and approved before implementation.

## Goal

A signed-in user can keep more than one separate set of finances and choose
which one the app shows, for example:

- **Personal**: private, only the user.
- **Household**: shared with collaborators who can view or edit it.

This document calls each set a **space** (user-facing name: Decision 1). The
server already calls one user's records a *dataset* (`dataset.initialize`);
a space is a dataset that can have more than one member.

## Starting point

Every synced record belongs to exactly one user today:

- All five tables (`custom_account_types`, `accounts`, `categories`,
  `transactions`, `monthly_plans`) have `owner_id → auth.users`.
- Row-level security is `read_own`; writes go only through
  `fundly_apply_operations`, which takes `actor = auth.uid()`.
- Uniqueness is per owner: account, category and custom type names. Any
  number of budget accounts since 2026-11-23 (schema v13), so the old
  `accounts_one_budget_account` index is gone.
- Writes are serialized per user with
  `pg_advisory_xact_lock(hashtextextended('fundly:' || actor, 0))`.
- Tombstones (`fundly_deleted_records`) and revision conflicts are
  owner-scoped (supabase/SYNC_PROTOCOL.md).
- PowerSync streams `WHERE owner_id = auth.user_id()`
  ([powersync/sync-config.yaml](../powersync/sync-config.yaml)).
- The device keeps one synced store per user (`fundly_sync_<user id>`), and
  switches stores when the signed-in user changes.
- The signed-out local database (schema v13) is a separate, single dataset.

So "whose data is this" is answered by the user everywhere. This proposal
moves that answer to the space, and makes the user's access come from
membership.

## What stays the same

- Financial rules and calculations (CLAUDE.md §4) apply inside each space,
  unchanged: balances, Spending and Inflow totals, transfers, card payments,
  Plans, Ready to assign and carry-over.
- Each space has its own accounts, categories, plans and budget account.
- The signed-out local mode: one dataset on the device, no spaces.
- Backup formats 1–6 for local mode.
- PHP only; no currency conversion.

## Proposed design

### Server

- New `spaces` table: `id`, `name`, `created_by`, timestamps, `revision`.
- New `space_members` table: `space_id`, `user_id`, `role`
  (`owner`, `editor`, `viewer`; Decision 3), timestamps. A space always has
  at least one owner.
- The five record tables get `space_id` in place of `owner_id`. Every
  per-owner constraint becomes per-space: name uniqueness, one budget
  account, composite foreign keys, tombstones and revision conflicts.
- Records also keep `created_by` and `updated_by` (Decision 6), so a shared
  space can answer "who recorded this".
- Read access: members of the space. Writes still go only through
  `fundly_apply_operations`, which now takes the target space; the server
  checks the actor's role (editor or owner) for every operation.
- The write lock becomes per space, so two members writing at once are
  serialized the same way one user's devices are today.
- `dataset.initialize` runs per space, so each new space gets the default
  categories once.
- Linked liability rows (Plans) stay server-generated, per space.
- Write receipts stay per batch, as today.

### Sync

- One stream for the user's spaces and memberships (names, roles, members).
- One stream for a space's records, subscribed with the selected `space_id`
  and checked against `space_members` on the server. Losing membership removes
  that space's rows from the device at the next checkpoint.
- C0 proved this membership filter on iOS and Chrome (self-hosted
  PowerSync), including removal; see the
  [C0 findings](SHARED_SPACES_C0_FINDINGS.md) for what C1–C3 must add.

### App

- One synced store per space on the device (Decision 5), named from the user
  and the space. Switching spaces swaps the store the same way changing users
  does today, so repositories and screens stay unaware of spaces.
- Profile tab gets a **Spaces** section: the list, the active one marked,
  role shown, tap to switch; Create space; for owners, Manage members.
  Preferred layout (product owner, 2026-11-24; confirm in the C2 plan): a
  row at the bottom of the signed-in card shows the active space and the
  user's role, with a chevron. Tapping it opens a bottom sheet listing the
  user's spaces (own and shared, active one ticked, role shown, tap to
  switch) and Create space, later Manage members for owners. Not a
  collapsible card, and not a separate section below the card.
- The active space's name appears where it is useful (Profile, and the top of
  Spending and Plans), so the user always knows which finances they see.
- The device remembers the last active space per user.
- Viewers get the read-only mode that S5.2 already built.

### Inviting collaborators

- An owner creates an invite for an email address and a role, and shares the
  invite link themselves (Messages, email). The app sends no email
  (Decision 4).
- The invitee signs in with Google using that email, opens the link, sees the
  space name, who invited them and the role, and accepts or declines.
- Invites are single-use, expire (for example after 7 days) and can be
  revoked by an owner.
- Owners can change roles and remove members. Any member can leave. The last
  owner cannot leave without making someone else owner or deleting the space.

### Existing data

- A server migration creates a **Personal** space per existing user, owned by
  them, and moves all their records into it. No records change otherwise.
- The device's existing per-user store is replaced by the Personal space's
  store; it downloads again (same as a new device).
- Backups become per space. S6 settled format 7 for one user's data; how
  export and restore work per space is decided in C2.

## Slices

Each slice is planned in detail, approved, implemented, verified and reviewed
on its own, and the agent stops after each one.

| Slice | Content | Outcome |
|---|---|---|
| C0 | Prototype: membership-filtered sync streams with a `space_id` parameter on iOS and Chrome; revoking membership removes rows locally; switching between two space stores. | Go/no-go evidence, like S1 |
| C1 | Server: `spaces`, `space_members`, `space_id` on all records, per-space constraints, locks, RLS and write API; backfill Personal spaces; pgTAP and concurrency tests. The app moves to the new protocol in the same release, always using the Personal space. | Same app behavior on the new model |
| C2 | App: per-space stores, Spaces section, create, rename and switch spaces, per-space default categories. | **Option A: multiple private spaces** |
| C3 | Sharing: invites, accept/decline, members list, roles, remove and leave; viewer read-only. | **Option B: shared spaces** |
| C4 | Collaboration polish: "Added by" on transactions, refused-change messages that name the conflicting change, delete a shared space. | Household-ready |

Recommended order: finish cloud sync S6 and S7 first, then C0–C2, then C3–C4.

## Decisions

Approved 2026-11-22: 1–10, each as recommended.

1. **User-facing name.** "Space" (recommended: neutral, and avoids clashing
   with the *budget account* and the Profile tab). Alternatives: "Budget",
   "Profile", "Book".
2. **Scope and order.** Private spaces first (C0–C2), sharing after (C3–C4)
   (recommended). Alternative: build sharing in one go.
3. **Roles.** Owner, editor, viewer (recommended). Alternative: owner and
   editor only.
4. **Invites.** Email-bound invite link that the owner shares (recommended; no
   email service to run). Alternatives: the app sends invite emails through
   Supabase, or an open join code anyone with the code can use (simpler but
   weaker).
5. **Device storage.** One store per space (recommended; existing repositories
   and financial code stay unchanged). Alternative: one store holding every
   space, with a `space_id` filter in every query.
6. **Who recorded it.** Store `created_by` and `updated_by` and show "Added by"
   in shared spaces (recommended). Alternative: no attribution.
7. **Money between spaces.** Accounts belong to one space; no transfers across
   spaces in the first version (recommended). Money given to the household is
   recorded as Spending in Personal (for example a "Household contribution"
   category) and Inflow in Household. Alternative: a cross-space transfer
   type, which needs new accounting rules.
8. **Leaving or removal.** The space's data is removed from that member's
   devices; their unsent changes are refused and listed in Refused changes,
   where they can be exported (recommended).
9. **Deleting a space.** Owner only, after typing the space name; removes it
   for everyone (recommended). Personal cannot be deleted while it is the
   user's only space.
10. **Timing.** After S6 and S7 (recommended), so cloud sync ships first and
    the Personal-space migration covers existing cloud data.

## Risks

- **Privacy is the main risk.** A wrong membership check would show one
  person's finances to another. Every table and operation needs tests for
  non-members, removed members and viewers trying to write.
- PowerSync membership-filtered streams, and removal of rows when access ends,
  are unproven here; C0 checks them before any schema work.
- More concurrent writers mean more revision conflicts. S5.4's Refused changes
  screen handles them, but messages need to make sense to a person who did not
  make the other change.
- C1 rewrites every write function and constraint on live data. It needs a
  migration test on a copy of production data and a rollback plan.
- Free-tier limits (PowerSync buckets, Supabase rows and connections) grow
  with members and spaces; check before C3.
- An invite link that leaks lets the wrong person request access; binding
  invites to an email and making them expire limits this.

## Verification (for every slice)

- `dart format`, `flutter analyze`, `flutter test`.
- pgTAP tests for access by owners, editors, viewers, non-members and removed
  members on every table and operation; concurrency tests for two members
  writing to one space.
- Two Google accounts on two devices (iOS and Chrome): invite, accept, edit on
  both, conflict, remove, leave, and confirm balances and Plans agree.
- Domain tests still pass unchanged: financial rules do not depend on spaces.
