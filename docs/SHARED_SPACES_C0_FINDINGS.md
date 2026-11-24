# Shared spaces C0: findings and go/no-go

Date: 2026-11-24

Status: **accepted 2026-11-24: go.** Recorded in CLAUDE.md §11 and the
roadmap; the proposal corrections below are applied and the local C0
environment is removed. Slice C0 of
[SHARED_SPACES_PROPOSAL.md](SHARED_SPACES_PROPOSAL.md), planned in
[SHARED_SPACES_C0_PLAN.md](SHARED_SPACES_C0_PLAN.md) (approved 2026-11-24).
No Fundly app code, schema, backup format, production server object or
production sync config changed.

## Recommendation: go

The proposal's sync design works. One device store per space, subscribed with
the space's ID and checked against membership on the server, kept every
space's data where it belongs on the VM, the iOS simulator and Chrome, and
removed a space from a member's device when their membership ended. All ten
planned checks and the owner's manual round passed.

Recommend starting the **C1 plan** with the design as proposed, plus the
changes below (findings 2, 3, 5 and 6). C1 keeps one Personal space per user,
so these findings mostly shape C2 and C3; C1 must not paint them into a corner.

## What was tested

Everything ran locally (Decision C0-1, local fallback: the PowerSync free plan
allows one instance, which is production's):

- a separate local Supabase stack with stand-in tables `c0_spaces`,
  `c0_space_members` and `c0_entries`, membership-based read rules, and one
  write function that checks the writer's role, serializes writes per space
  and applies each batch once;
- the self-hosted PowerSync service (open edition 1.29.1) with two streams:
  the user's spaces and members (automatic), and one space's records
  (subscribed per store with `space_id`, filtered by a membership subquery);
- three test users: A owner, B member, C outsider.

| Evidence | Result |
|---|---|
| Schema rehearsal (21 assertions) | Pass |
| C0.1 connection check (7) | Pass |
| C0.2 stream checks 1-2, 4-8 and 8b (6 tests, 3 runs) | Pass |
| C0.2 API checks 3, 9, 10 (7, 2 runs) | Pass |
| C0.3 switching checks (2 tests) on the VM, iOS simulator and Chrome | Pass |
| C0.3 manual round on the simulator and Chrome (owner) | Pass |
| Fundly's own suite during C0 (format, analyze, 1156 tests) | Pass, unchanged |

Commands and dates are in the
[C0 README verification log](../tool/sync_probe/cloud/c0/README.md).

## What was proven

1. **Each store holds only its own space.** An outsider who subscribes with
   another space's ID receives nothing, and gets nothing through the API
   either: no reads, no writes, no adding themselves.
2. **Roles work end to end.** An editor's local write uploads and reaches the
   owner's device, recorded as written by the editor. A viewer still reads,
   but their write is refused and the local row reverts by itself.
3. **Membership changes reach devices.** A role change and a removal each
   re-evaluate the streams. A removed member's device loses the space, its
   members and its records, whether it was connected at the time or offline
   and reconnected later.
4. **A removed member's unsent change is kept.** It is refused by the server,
   logged on the device (where C3 can show it in Refused changes, Decision 8)
   and the space still leaves the device.
5. **Writes are safe with several members.** The same batch sent twice
   applies once; 20 batches from two members at once all apply; two edits of
   the same revision: one applies, the other is refused as a conflict.
6. **Switching spaces is cheap.** Switching back to a space reuses its copy on
   the device, without downloading it again, and picks up changes made in the
   meantime. Several stores can be open at once on iOS and in Chrome, a
   reload keeps them, and two Chrome tabs on different spaces stay separate.

Locally, every change reached the device within about 0.25 seconds (one
polling interval of the tests). Hosted timings will be slower and are not
claimed here.

## Findings that change the plan

| # | Finding | What to do | Slice |
|---|---|---|---|
| 1 | The design works as proposed | Keep it: a "my spaces" stream plus a per-space records stream with `subscription.parameter('space_id')` and a membership subquery | C1 |
| 2 | **A new member's first sync can finish empty.** Once, the first sync completed before the just-granted membership had reached PowerSync; the data arrived a moment later | Treat a space as ready only when it appears in the member's own spaces stream, not when the first sync finishes; show "Loading" until then | C2, C3 |
| 3 | **Refused uploads must be logged and completed, never retried forever.** If a removed member's queued change is retried, PowerSync holds every later update ("Could not apply checkpoint due to local data"), so the removed space **stays on the device** | Keep Fundly's current rule (log to Refused changes, complete the batch) for every refusal, and add "not a member" and "viewer" as refusals the uploader logs | C1, C3 |
| 4 | Refused local writes revert by themselves | No new work; matches Fundly today | — |
| 5 | **Stream subscriptions must be released** when a store closes, or the SDK warns of leaked subscriptions | The store switcher unsubscribes when it closes a space's store | C2 |
| 6 | **One browser holds one signed-in user.** Supabase shares the session across every tab of a site | Fits the app; no work. Spaces switch inside one user, never by signing in again | — |
| 7 | Per-space stores work in Chrome: several in a tab, kept across a reload, two tabs on different spaces | Allow different spaces in different tabs (closes Decision C0-4) | C2 |

## Limits of this evidence

- **Self-hosted, not hosted PowerSync.** Same sync engine and the same
  edition 3 stream syntax that production already uses; the hosted behaviour
  of the per-space streams is confirmed when C1 deploys (a release checklist
  row after the usual backups), before any user has a second space.
- **Stand-in tables, not Fundly's.** The five real tables, their constraints,
  composite keys and tombstones move to spaces in C1 and need their own pgTAP
  and concurrency tests, as the proposal says.
- **Managed views, not raw tables.** C0 checked scoping, removal and
  switching, which do not depend on the raw-table setup S1 already proved.
  C1 reruns these behaviours on the real raw-table store.
- **Not covered:** Google sign-in (C0 used email users), a physical iPhone,
  Android, timings over the internet, and the free-plan bucket and connection
  counts at household scale (the proposal already flags this for C3).

## Corrections for the proposal

Before the C1 plan, the proposal's "Starting point" needs updating:

- "one budget account (`accounts_one_budget_account`)": several budget
  accounts are allowed since 2026-11-23 (schema v13); that index is gone.
- "The signed-out local database (schema v12)": it is v13.
- "Backups become per space (format decided with S6)": S6 is done and chose
  format 7; how backups work per space is a C2 decision.

## Next steps

1. Owner reviews this document and decides go or no-go.
2. On go: record the decision (CLAUDE.md §11 and the roadmap), apply the
   proposal corrections above, and remove the local C0 environment with
   `tool/sync_probe/cloud/c0/down.sh --wipe` (Decision C0-3). The C0 files
   stay in the repository as the record, like the S1 probe.
3. Then plan C1 in detail for approval. C1 is the riskiest slice: it rewrites
   every write function and constraint on live data, so its plan needs a
   migration test on a copy of production data and a rollback plan.
