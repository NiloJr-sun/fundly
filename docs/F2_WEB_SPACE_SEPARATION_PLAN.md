# F.2: Spaces mix on the web (fix plan)

Date: 2026-11-24

Status: **proposed**, waiting for the product owner's decisions (F.2-1 to
F.2-3). The agent stops after each step, never commits or pushes, and does not
touch production; production writes and deploys are run by the owner.

## Problem

On the web, every space other than Personal also shows the user's Personal
records. On iOS each space shows only its own records.

## Cause

App 1.3.0 turns off the old automatic stream `fundly_user_data` (kept for apps
1.2.x) with `SyncOptions(includeDefaultStreams: false)`
([powersync_store.dart](../lib/core/sync/powersync_store.dart), `_start`),
then subscribes to `fundly_spaces` and to `fundly_space_data` for one space.

- **iOS:** sync runs inside the app and respects the option.
- **Web:** PowerSync 2.6.2 runs sync in a shared worker and sends it the
  options as a message (`StartSynchronization`,
  `powersync-2.6.2/lib/src/web/sync_worker_protocol.dart`). That message has
  no `includeDefaultStreams` field, so the worker uses the default, `true`
  (`sync/options.dart`), and also subscribes to `fundly_user_data`.
- `fundly_user_data` is filtered only by `owner_id = auth.user_id()`, which
  since C2 matches exactly the Personal records. Every space's store on the
  web therefore downloads that space's records **plus all of Personal**.

The C2 stream checks (`tool/sync_probe/test/c2_space_streams_test.dart`) run
in the Dart VM, without the worker, so they could not catch it.

## Evidence (local stack, 2026-11-24)

A throwaway probe ran against `tool/sync_probe/cloud/fundly-local`
(self-hosted PowerSync 1.29.1). The probe was deleted afterwards and the
config restored. A "web" client is simulated as default streams **on**, the
way the worker behaves.

| Client | Current config | With the fix |
|---|---|---|
| 1.2.x (automatic stream only, no parameter) | Personal only | Personal only |
| Web 1.3.0 in a second space (defaults on, no parameter) | **Personal + space** | Personal + space (unchanged; needs the new app) |
| Web, fixed app in a second space (defaults on, parameter) | n/a | **space only** |
| iOS, fixed app (defaults off, parameter) | n/a | space only |
| Web, fixed app in Personal | n/a | Personal only |
| A store that had leaked, reconnecting with the parameter | n/a | **Personal rows removed**, space rows kept |

The PowerSync docs confirm that `connection.parameter()` is allowed in stream
queries, including `auto_subscribe` ones. They do not say what a parameter the
client never sent evaluates to. The run above shows that `IS NULL` is true for
it, so 1.2.x clients keep their stream.

## Impact so far (web only)

- **No data crossed spaces on the server.** Writes check the record's space:
  editing a Personal record while in another space, or using a Personal
  account in another space's transaction, is refused with
  `record_not_accessible` and appears under Refused changes. Nothing is moved.
- **Wrong figures on screen** in non-Personal spaces: Available money, Ready
  to assign, account lists and pickers include Personal.
- **Spaces created on the web may have no default categories.** First-time
  setup (`initializeDatasetIfEmpty`) runs only when the store's first download
  finds no categories, and the leaked Personal categories make it skip. Once
  the fix removes the leaked rows, such a space would have no categories. See
  Decision F.2-3.
- Personal (on every platform) and all spaces on iOS are not affected.

**Until the fix is live:** on the web, edit only in Personal; use the iPhone
for other spaces.

## Proposed fix

### 1. Sync config

In `powersync/sync-config.yaml`, add one condition to each of the five
`fundly_user_data` queries:

```yaml
FROM accounts WHERE owner_id = auth.user_id()
  AND connection.parameter('space_streams') IS NULL
```

A client that sends `space_streams` (app 1.3.1 and later) no longer receives
the old stream, whatever its default-streams setting. Apps 1.2.x send no
parameters and are unchanged. The parameter comes from the client, so it is
only ever used to **receive less**; access stays decided by `auth.user_id()`
and the membership subqueries. Update the file's header comment to say so.

### 2. App

In `PowerSyncStore._start`, connect with:

```dart
const ps.SyncOptions(
  includeDefaultStreams: false,
  params: {'space_streams': true},
)
```

`params` does reach the web worker (`syncParamsEncoded`). Keep
`includeDefaultStreams: false` so iOS behaves the same as today even against
an older config. Put the options in one public constant so a unit test can
check them.

### 3. Tests

- **Sync probe:** extend `c2_space_streams_test.dart` with the web-like client
  (defaults on, parameter → its space only), the leaked store reconnecting
  (Personal rows removed), and the 1.2.x client (still exactly Personal).
  This becomes the permanent regression check for the worker behaviour.
- **App:** a unit test that the store's connect options carry
  `space_streams` and turn the default streams off.
- `dart format`, `flutter analyze`, the full app test suite, and the C2 and
  C3 stream probes on the local stack.
- **Manual, Chrome:** a second space shows only its own records, and the leak
  disappears from a browser that already had it, without clearing site data.

## Release

The config change and the app change work in either order: the new
condition does nothing until a client sends the parameter, and the parameter
does nothing against the old config. Deploy the config first.

1. **Sync config (hosted):** paste, Validate, Deploy (OPERATIONS.md, PowerSync
   config), after rehearsing on the local stack. Rerun the isolation checks.
2. **Web:** release 1.3.1 (6) (see Decision F.2-1 for which code).
3. **iOS:** not affected, so no install is needed now; the change ships with
   the next iOS release.
4. Check on Chrome, then record it in a short release checklist.

**Rollback:** revert the config (the leak returns, nothing else breaks) or roll
the web back in Vercel. Neither changes stored data, and no schema or backup
format changes.

## Decisions for the product owner

### F.2-1. Which code ships to the web

`main` (and `origin/main`) already holds C3.1 (server, local only, and C3
columns in `sync-config.yaml`) and C3.2 (sharing data layer, synced schema
v4). The live site still serves the 1.3.0 code: its `main.dart.js` has none of
the C3.2 invite calls. A normal push to `main` would therefore ship C3.2 to the
web against a server without C3.1.

- **A. Hotfix branch from the 1.3.0 release (recommended).** Branch
  `hotfix/1.3.1` from `9cf1bd3`, apply steps 1–3 there and set version 1.3.1
  (6). Deploy that branch's Vercel build to production (promote its preview
  deployment). Deploy the hosted sync config from that branch, because main's
  config needs the C3.1 migration. Then apply the same change on `main` so C3
  keeps it.
- **B. Fix on `main`.** Simpler in git, but ships unreleased C3.2 code to the
  web. Not recommended.

**Before either:** check in the Vercel dashboard why the pushes of `6103bd3`
and `c7f45cc` did not reach production (failed build, or deploys paused). The
next push to `main` may otherwise deploy C3.2 unexpectedly.

### F.2-2. Parameter name

`space_streams: true` (recommended): it names what the client understands,
and later stream changes can test the same flag. The alternative is a version
number (`app_version`), which invites version logic in the config.

### F.2-3. Spaces left without default categories

- **A. Check production first (recommended).** The owner runs a read-only
  query listing non-Personal spaces with no categories once the leaked rows
  are gone, that is, spaces with no category whose `space_id` is theirs. If
  there are none, nothing more is needed. If there are a few, the owner
  initializes each by a one-off `dataset.initialize` call for that space. It
  is idempotent: it adds the defaults only when the space has no categories.
- **B. Retry in the app on every open** when the synced store has no
  categories. This repairs automatically, but it would also re-add the
  defaults to a space whose user deliberately deleted every category.

## Follow-up

- Report the upstream bug to PowerSync (`includeDefaultStreams` is not
  forwarded to the shared sync worker in `powersync` 2.6.2). The parameter
  stays harmless after an upstream fix.
- When done: a row in the CLAUDE.md decisions log, F.2 in ROADMAP.md, and the
  config deploy in `powersync/README.md`'s log.
