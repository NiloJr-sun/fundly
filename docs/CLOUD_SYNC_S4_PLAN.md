# S4 — Authentication and isolated local stores: proposal

Date: 2026-11-20
Status: **approved 2026-11-20; implemented, manual sign-in checks pending.**

## Implementation record

- Dependencies added: `supabase_flutter` 2.18.3, `google_sign_in` 7.2.0 and
  `crypto` 3.0.8 (declared explicitly because the nonce hash imports it). iOS
  Swift package pins (GoogleSignIn 10.1.0) are committed in
  `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- Decision 6: the preferred nonce approach works; **Skip nonce checks stays
  off**. `GoogleSignIn.initialize` may be called only once per app run, so the
  nonce is generated once per run and reused for each sign-in in that run;
  Supabase checks it every time.
- Run with cloud features:
  `flutter run --dart-define-from-file=config/cloud.json` (web:
  `flutter run -d chrome --web-port 7358 --dart-define-from-file=config/cloud.json`).

| Date | Check | Result |
|---|---|---|
| 2026-11-20 | `dart format .`, `flutter analyze` | 0 changed; no issues |
| 2026-11-20 | `flutter test` | 869 passed (844 before, 25 new) |
| 2026-11-20 | `flutter build ios --simulator --debug` and `flutter build web`, with `config/cloud.json` | Both built |
| 2026-11-20 | Simulator: backed up `fundly.sqlite`, installed, launched signed out | Launches on existing data; schema 12, counts unchanged (6 accounts, 13 categories, 6 transactions, 7 monthly plans), `integrity_check` ok, no foreign-key errors |
| _pending_ | Owner: Google sign-in on the simulator and web, restart, sign-out, offline relaunch | Not yet run |

## Follow-up: login page (approved 2026-11-22)

- In builds that can sign in (cloud config, iOS or web), a signed-out launch
  opens a login page: **Continue with Google** (the only sign-in method; a
  first-time Google user is created automatically, so there is no separate
  sign-up) and **Use without an account**, which opens the local `fundly`
  data as before.
- The "Use without an account" choice is remembered on the device
  (`shared_preferences`, key `fundly.localUseChosen`, added as a direct
  dependency; it was already transitive through `supabase_flutter`). Signing in
  clears it, so a sign-out or a revoked session returns to the login page.
- While using local data, Account tab ⋮ → **Sign in with Google** still works.
  Local data is not moved into the account (S6).
- Builds without the cloud config and Android skip the login page.
- The button is the app's teal filled button with Google's "G" logo, cropped
  from Google's official sign-in button assets (`assets/images/`), on a small
  white tile, as Google's branding guidelines require for the logo.
- No schema change (v12), no backup format change (6).

| Date | Check | Result |
|---|---|---|
| 2026-11-22 | `dart format`, `flutter analyze` | 0 changed; no issues |
| 2026-11-22 | `flutter test` | 883 passed (869 before, 14 new) |
| _pending_ | Owner: login page on the simulator and web | Not yet run |

## Starting point

S3 is complete: the hosted Supabase project (Tokyo) and the JP PowerSync
instance replicate exactly the five Fundly tables, both isolation checks pass
on the hosted services, and Google sign-in works through Supabase's browser
flow. The Fundly app itself is unchanged: one local drift database named
`fundly` (schema v12), opened once by `appDatabaseProvider`, with no Supabase,
Google or PowerSync dependency.

S4 adds sign-in to the app and gives each signed-in user their own local
database. It does **not** sync anything. Uploads, downloads and the switch to
UUID-based synced tables are S5; importing existing local data into the cloud
is S6.

## What the user sees

- **Signed out (default, unchanged):** the app opens the existing `fundly`
  database exactly as today. Nothing about local use changes.
- **Account tab ⋮ menu → Sign in with Google.** On iOS this opens Google's
  native sign-in sheet; on web it redirects to Google and back.
- **Signed in:** the app switches to that user's own database, which starts
  empty apart from the default categories. A line at the top of the Account
  tab shows "Signed in as name@gmail.com · Not syncing yet", and the ⋮ menu
  offers **Sign out**.
- **Sign out:** the app returns to the original local database. The user's
  database stays on the device and reopens on the next sign-in.
- Cancelling sign-in changes nothing. A failed sign-in shows a short message
  and stays on the current data.

Until S5, the signed-in database is a **preview store**: it is not backed up
to the cloud, and S5 may replace it when the synced UUID tables arrive (see
Decision 1). Real data should stay in the signed-out local database until then.

## Decisions to approve

### Decision 1 — Signed-in store is a disposable preview until S5

The signed-in database uses the current v12 schema so every screen works
unchanged. S5 introduces UUID-keyed raw tables for sync (S1 finding 1–2),
which is a different file format. Proposal: S5 discards and recreates
per-user databases that were created in S4 rather than migrating them, because
they never hold synced or imported data. The original `fundly` database is
never touched by either step.

Alternative: hide sign-in entirely until S5 is ready. That delays end-to-end
testing of sign-in, session restore and store switching on real devices,
which is the main risk S4 retires.

### Decision 2 — Cloud features only in builds that carry the cloud config

The Supabase URL, publishable key and Google client IDs are passed at build
time with `--dart-define-from-file=config/cloud.json`. That file is git-ignored;
a committed `config/cloud.example.json` documents the keys. A build without the
file shows no sign-in option and behaves exactly like today, so the current
release flow and all widget tests stay unaffected.

All of these values are public by design (they ship inside the app), but
keeping them out of the repository keeps the project ref out of builds that do
not need it and makes test and production projects easy to swap.

### Decision 3 — Store selection and isolation

- Database names: `fundly` for signed-out use (unchanged) and
  `fundly_user_<supabase user id>` per signed-in user. The user ID is a UUID
  and is validated before it becomes a file name. On web each name is a
  separate browser database.
- `appDatabaseProvider` watches the active identity. When it changes, the old
  database is closed, every repository and stream provider rebuilds against the
  new one, and the app's navigation resets to the home tabs, so no screen can
  keep showing another user's records.
- The local database is never attached to the first Google account that signs
  in (approved default). Moving it to the cloud is the explicit S6 step.

### Decision 4 — Session policy

- The session is restored on launch, including offline. An expired access
  token while offline does **not** sign the user out; their data stays usable
  and the token is refreshed when the network returns. This matters for S5,
  where pending writes must survive.
- The app returns to signed-out mode only on an explicit **Sign out** or when
  Supabase reports the session as revoked (for example, the refresh token was
  invalidated). In both cases the user's database is kept on the device.
- Sign-out in S4 has nothing pending to lose. S5 adds the approved rule: never
  discard unsynced writes silently.

### Decision 5 — Backup and restore while signed in

- **Export backup** works in both modes and exports the store that is open.
- **Restore from backup** stays available signed out and is **blocked while
  signed in**, with an explanation, as approved in the plan. Restoring into a
  cloud dataset needs its own design (S6).

### Decision 6 — iOS sign-in method and nonce

iOS uses the native Google SDK (`google_sign_in` 7) and passes the Google ID
token to Supabase (`signInWithIdToken`), using the recorded iOS client ID and
the Web client ID as the server client ID. Web uses Supabase's OAuth redirect
(`signInWithOAuth`) back to the app's origin; for development that is
`http://localhost:7358`, already an allowed redirect.

Supabase checks a nonce in the ID token when one is present. The preferred
approach is to generate a nonce, give its SHA-256 hash to Google and the raw
value to Supabase. If the plugin version cannot pass a nonce on iOS, the
fallback is enabling **Skip nonce checks** for the Google provider in Supabase,
which weakens replay protection for stolen ID tokens. I will try the
preferred approach first and ask before falling back.

### Decision 7 — Dependencies

| Package | Version | Why |
|---|---|---|
| `supabase_flutter` | ^2.18.3 | Auth session, refresh and restore; later the S5 upload RPC |
| `google_sign_in` | ^7.2.0 | Native Google sign-in on iOS |

Both resolved together with drift 2.35.4 in the S1 probe. `supabase_flutter`
brings transitive packages for session storage (`shared_preferences`) and
callback links (`app_links`). `crypto` for the nonce hash is already available
transitively; it is added explicitly only if the analyzer requires it.
PowerSync and `uuid` are not added until S5. Current versions are rechecked on
pub.dev before adding.

Session tokens are stored by `supabase_flutter`'s default storage (app-private
preferences on iOS, browser local storage on web). Keychain-backed storage
would need another dependency (`flutter_secure_storage`); I propose deferring
it and listing it as a known limitation unless you want it in S4.

## Implementation

| File | Change |
|---|---|
| `pubspec.yaml`, `pubspec.lock` | Add the two packages |
| `config/cloud.example.json`, `.gitignore` | Documented keys; ignore `config/cloud.json` |
| `lib/core/config/cloud_config.dart` | New: reads the build-time values; `isConfigured` |
| `lib/main.dart` | Initialize Supabase only when configured |
| `lib/features/auth/domain/auth_identity.dart` | New: signed-out or signed-in (user ID, email) |
| `lib/features/auth/data/auth_repository.dart` | New: watch identity, sign in with Google, sign out; Supabase-backed, with a fake for tests |
| `lib/features/auth/data/google_sign_in_*.dart` | New: iOS native and web redirect flows |
| `lib/features/auth/presentation/` | New: ⋮ menu items, signed-in status line, error message |
| `lib/core/database/app_database.dart` | Database name parameter; provider follows the active identity |
| `lib/app/app.dart` | Reset navigation when the identity changes |
| `lib/features/accounts/presentation/accounts_screen.dart` | Menu entries and status line |
| `lib/features/backup/presentation/restore_backup.dart` | Blocked while signed in |
| `ios/Runner/Info.plist` | Google URL scheme (reversed iOS client ID, public) |
| `test/...`, `test/helpers/` | New tests and a fake auth repository |

No drift schema change (stays v12), no backup format change (stays 6), no
financial rule change, and no hosted service change.

## Tests and verification

Automated:
- Database name per identity, including rejection of a malformed user ID.
- Switching identity closes the old database and opens the right one; records
  written as user A are invisible as user B and in signed-out mode, and the
  signed-out data is unchanged after a round trip.
- Session policy: restored session, offline restore, explicit sign-out and
  revoked session map to the right identity.
- Widgets: no sign-in option without cloud config; sign-in and sign-out menu
  states; status line; restore blocked while signed in; cancelled and failed
  sign-in.
- `dart format .`, `flutter analyze`, full `flutter test` (844 today).

Manual (recorded with results):
- iOS simulator: sign in with Google, restart, sign out, sign in again (data
  reopens), signed-out data unchanged (row counts and `PRAGMA integrity_check`
  on `fundly.sqlite` before and after), relaunch with the network off.
- Web (`flutter run -d chrome --web-port 7358 --dart-define-from-file=…`): the
  same flow, plus a page reload while signed in.
- `flutter build ios --simulator --debug` and `flutter build web`, with and
  without the cloud config.

The expired-token check that S3 left open moves to S5, when the app first
connects to PowerSync.

## Not included

PowerSync, UUID tables and any upload or download (S5); importing local data
or cloud restore (S6); Android sign-in; the production web origin and release
(S7); deleting a user's local or cloud data from the app; household sharing.

## Risks

- Google sign-in on a physical iPhone is not covered by the simulator check;
  it is part of the S7 release matrix.
- Flutter web drift with multiple tabs: a tab that is already open does not
  learn about a sign-in or sign-out in another tab until it reloads.
- The free-tier Supabase project pauses after a week of inactivity; sign-in
  fails until it is resumed in the dashboard.
- The consent screen is in Testing mode, so only listed test users can sign in.

## Approval requested

1. Decision 1: preview signed-in store, recreated by S5.
2. Decision 2: cloud features only with `config/cloud.json`.
3. Decisions 3–5: store isolation, session policy, restore blocked while
   signed in.
4. Decision 6: native iOS ID-token sign-in, nonce first, ask before skipping.
5. Decision 7: add `supabase_flutter` and `google_sign_in`; defer keychain
   storage.

On approval, the §11 row in CLAUDE.md is added when S4 is delivered.
