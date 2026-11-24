# Shared spaces C2: private spaces in the app (plan)

Date: 2026-11-24

Status: **proposed, awaiting approval.** Slice C2 of
[SHARED_SPACES_PROPOSAL.md](SHARED_SPACES_PROPOSAL.md), after C0 (go) and C1
(deployed). The agent stops after each sub-slice and never commits or pushes;
production writes are run by the owner.

## Goal

From the proposal: **Option A, multiple private spaces.** A signed-in user
can create more spaces besides Personal (for example "Business" or
"Savings goals"), rename them, and switch between them; each has its own
accounts, categories, plans, budget accounts and default categories, and the
app always shows which space it is in. Sharing with other people is C3.

## Starting point

- **Server (C1):** records have `space_id`, `created_by`, `updated_by`; every
  user has a Personal space whose id is their user id; reads are by
  membership; writes and imports accept an optional `space_id` and check the
  role. `owner_id` is still required and equal to `space_id`, which only
  works for Personal spaces (it references a user). `spaces` and
  `space_members` exist but are not synced and have no client API.
- **Sync:** one automatic stream, `fundly_user_data`, filtered by
  `owner_id = auth.user_id()`. Apps 1.2.0 and 1.2.1 depend on it.
- **App:** one PowerSync store per user (`fundly_sync_<user id>`), opened by
  `syncedStoreProvider` from the signed-in identity; repositories and
  screens read whatever store it holds, so they never know about users or
  spaces. The synced store's local schema is v2. The uploader sends the
  envelope without `space_id`. After the first download, an empty store
  queues `dataset.initialize` (default categories).
- **C0 findings to apply:** a space is ready only when it appears in the
  member's own spaces list (not when the first sync ends); refused uploads
  are logged and completed (already so); stream subscriptions are released
  when a store closes; different spaces in different browser tabs work.
- **Preferred UI (owner, 2026-11-24):** a row at the bottom of the Profile
  card shows the active space and role, opening a bottom sheet with the
  spaces and Create space (proposal, App).

## What does not change

- Financial rules and calculations, inside every space.
- The signed-out local database (v13) and its backups.
- Apps 1.2.x: they keep working, showing and editing only Personal
  (Decision C2-1). No forced update; the minimum supported version stays
  1.2.0.
- Backup format 7 (a backup holds one space's records).
- Sharing, invites, roles other than owner in practice, leaving and deleting
  spaces (C3), "Added by" (C4).

## Proposed design

### Server

- **`owner_id` becomes Personal-only.** For a Personal space's records it
  stays the user's id; for any other space it is null. The rule becomes
  "`owner_id` is null or equals `space_id`", and the bridge trigger sets it
  from the space's `personal_of`. The existing stream therefore keeps sending
  1.2.x apps exactly their Personal records, and never another space's.
- **Space management, online only** (Decision C2-3), as SECURITY DEFINER
  RPCs with the same refusal style as C1 (`P0001`):
  - `fundly_create_space(id, name)`: creates a space owned by the caller,
    with the caller as owner; at most 10 owned spaces (Decision C2-5);
    idempotent for the same id and name.
  - `fundly_rename_space(id, name, expected_revision)`: owners only;
    revision-checked like other edits.
  - Names: trimmed, 1–40 characters, unique among the spaces the user owns
    ignoring ASCII case, like account names (Decision C2-6). Personal can be
    renamed; it stays the default space.
- Default categories for a new space come from the existing
  `dataset.initialize`, already per space since C1.

### Sync (Decision C2-2)

Two new **opt-in** streams beside the untouched `fundly_user_data`:

```yaml
fundly_spaces:            # the user's spaces and their members
  auto_subscribe: false
  queries:
    - SELECT ... FROM spaces WHERE id IN (SELECT space_id FROM space_members WHERE user_id = auth.user_id())
    - SELECT ... FROM space_members WHERE space_id IN (SELECT space_id FROM space_members WHERE user_id = auth.user_id())
fundly_space_data:        # one space's five tables
  auto_subscribe: false
  queries:
    - SELECT ... FROM accounts
      WHERE space_id = subscription.parameter('space_id')
        AND space_id IN (SELECT space_id FROM space_members WHERE user_id = auth.user_id())
    # ... same for the other four tables, same columns as today
```

`spaces` and `space_members` join the publication (with the replication
role's grants). Apps 1.2.x never subscribe to the new streams; app 1.3.0
turns off the automatic stream (`includeDefaultStreams: false`) and
subscribes to `fundly_spaces` and `fundly_space_data` for its store's space.

### App

- **One store per space** (Decision 5): Personal keeps
  `fundly_sync_<user id>`; another space uses
  `fundly_sync_<user id>_<space id>`. `syncedStoreProvider` opens the store
  for the **active space**, so repositories and screens stay unchanged.
  Switching closes the old store (releasing its subscriptions) and opens the
  other; its data is already on the device.
- **Active space:** remembered per user on the device; Personal when unset
  or when the remembered space is no longer listed.
- **Readiness:** a newly opened space counts as loaded only once it appears
  in its store's spaces list (C0 finding 2); until then the screens show the
  usual loading state, and `dataset.initialize` waits too.
- **Uploads** name the store's space (`space_id`) in every envelope.
- **Synced local schema v3:** adds `spaces` and `space_members` tables
  (migration test included). The signed-out database is untouched.
- **Profile card (option A):** a row at the bottom of the signed-in card
  shows the active space and role with a chevron; it opens a bottom sheet
  listing the user's spaces (active one ticked, role shown), **Create
  space** (a name field; online only) and, for owners, **Rename**.
- **Which space you are in:** when the user has more than one space, the
  space name appears at the top of Spending and Plans (Decision C2-7);
  with only Personal nothing changes on screen.
- **Per-space actions** (Decision C2-8): Export backup, Restore from backup
  and Reset all data act on the active space, and their wording says so.
  Copy device data (signed-out data into the account) targets Personal.
  Refused changes are per space (the active space's list).
- **Web:** different spaces in different tabs are allowed (C0-4); the
  remembered space is the last one chosen on that browser.

### Release

App **1.3.0 (5)** (Decision C2-10). Order: server migration, publication and
grants, PowerSync config (adds the two streams), then web, then iOS. During
the rollout 1.2.x keeps working on Personal. On upgrading, 1.3.0's Personal
store moves from the automatic stream to `fundly_space_data` and
re-downloads once (identical data).

## Sub-slices

### C2.1: Server and sync config (agent, local)

Migration (Personal-only `owner_id`, space RPCs, name rules, limit),
publication and `sync-config.yaml` changes, rollback file. Tests: pgTAP for
the RPCs (create, idempotent retry, limit, names, rename by owner only,
revision conflict, non-member refused) and for `owner_id` (null outside
Personal; records in a non-Personal space written through the write API);
all C1 and earlier tests unchanged. Local sync rehearsal with self-hosted
PowerSync (as in C0): an old-style client (automatic stream only) still gets
exactly Personal; a new-style client gets each space separately; a second
space's records never reach the old stream.

### C2.2: App data layer (agent, local)

Synced schema v3 and its migration test; store per (user, space) with the
explicit subscriptions; active-space provider and its persistence; readiness
rule; `space_id` in uploads; per-space initialize, export, restore and reset;
the space RPC client. Tests: unit and provider tests for switching, the
remembered space, readiness, envelopes; the existing app suite unchanged.

### C2.3: App UI (agent; owner reviews on the simulator and Chrome)

The Profile card row and bottom sheet, Create and Rename dialogs (name rules,
online-only message), the space name on Spending and Plans, per-space wording
on backup and reset. Widget tests for the sheet, dialogs and headers.

### C2.4: Release 1.3.0 (owner and agent)

Version bump; full local suite; deploy per the runbook (backups, migration,
publication and grants, PowerSync config, web, iOS); release checklist rows
for C2, including **the first hosted check of per-space streams** (C0's
limit): two spaces on the iPhone and Chrome, switching, a record in each
space staying in it, Personal unchanged on a 1.2.1 device during the rollout.
Docs (CLAUDE.md, roadmap, runbook, AGENTS.md) updated.

## Rollback

- **Server:** a prepared rollback restores the C1 rules (requires no
  non-Personal space to hold records, which is true until 1.3.0 is used; it
  checks and refuses otherwise). The new streams can be removed from the
  config; the old stream never changed.
- **App:** reinstall 1.2.1 (iOS) or roll back the web deploy. 1.2.1 only uses
  Personal, so other spaces stay on the server, untouched, until 1.3.0 is
  back. Synced schema v3 is only an addition, but an older app cannot open a
  newer local database: rolling the iPhone back means deleting the app and
  signing in again (signed-in data downloads again; take the usual export
  first).

## Decisions for the product owner

- **C2-1. Old apps.** *(Recommended)* Keep 1.2.x working on Personal: the
  existing stream stays, and `owner_id` stays only for Personal records. No
  forced update. Alternative: raise the minimum version to 1.3.0 and drop
  `owner_id` now (simpler server, every device must update first).
- **C2-2. Streams.** *(Recommended)* New opt-in streams; 1.3.0 switches off
  the automatic one (one re-download of Personal on upgrade). Alternative:
  keep Personal on the automatic stream in 1.3.0 and use the new stream only
  for other spaces (no re-download, two ways of syncing to maintain).
- **C2-3. Creating and renaming.** *(Recommended)* Online only, like Reset.
  Alternative: queue them offline (more complex: a store for a space the
  server does not know yet).
- **C2-4. Deleting a space.** *(Recommended)* In C3, together with leaving
  and removal, since all three make a space disappear from devices and need
  the same handling of unsent changes. Alternative: delete private spaces in
  C2 (builds that handling now).
- **C2-5. Limit.** *(Recommended)* At most 10 spaces owned per user (free
  plan sizes). Alternative: another number, or none.
- **C2-6. Names.** *(Recommended)* Like account names: trimmed, 1–40
  characters, unique among your own spaces ignoring case; Personal can be
  renamed. Alternative: Personal's name fixed.
- **C2-7. Space name on screens.** *(Recommended)* At the top of Spending and
  Plans only when you have more than one space. Alternative: always, or only
  on Profile.
- **C2-8. Backups, reset and copy.** *(Recommended)* Export, restore and
  reset act on the active space; copying signed-out device data goes to
  Personal. Alternative: a space picker in each flow.
- **C2-9. Profile UI.** *(Recommended)* Option A as preferred on 2026-11-24
  (card row and bottom sheet). Alternative: a separate Spaces section.
- **C2-10. Version.** *(Recommended)* 1.3.0 (5); minimum supported stays
  1.2.0.

## Risks

- **Hosted per-space streams are new** (C0 ran self-hosted). Mitigation:
  local rehearsal in C2.1, then a dedicated release-checklist row with two
  spaces on two devices before sign-off.
- **A record in the wrong space** would show one space's money in another.
  Mitigation: the store's space is fixed when it opens and sent with every
  upload; the server checks membership; tests write in one space and check
  the other.
- **Store switching** could leave a subscription or connection open.
  Mitigation: provider tests and the C0 rule (unsubscribe on close).
- **Upgrade re-download** of Personal: small today, observed in the
  checklist.
- **Synced schema v3**: covered by the migration test and the release
  checklist.
