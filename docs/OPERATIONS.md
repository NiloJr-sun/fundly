# Fundly operations runbook

How to deploy, roll back, recover and keep an eye on Fundly's cloud sync.
Written for the owner as the only operator (cloud sync S7.3). Commands run from
the repository root on the Mac unless a step says otherwise.

## What runs where

| Part | Where | How it is deployed |
|---|---|---|
| Database, Auth, write API | Supabase project `fundly` (`jiiuukimazvcxautvmya`, Tokyo), free plan | Migrations in `supabase/migrations/`, pushed with the Supabase CLI |
| Sync | PowerSync instance (JP), free plan | `powersync/sync-config.yaml`, pasted into the PowerSync dashboard |
| Web app | Vercel, <https://fundly-budget.vercel.app> | A push to `main` builds with `tool/vercel_build.sh` (`vercel.json`) |
| iOS app | The owner's iPhone | Release build installed from the Mac with `devicectl`; no TestFlight |
| Android | Not verified (no device; D6) | — |

Values and where they live. None of them belong in the repository or a chat:

| What | Where |
|---|---|
| App cloud settings (public) | `config/cloud.json` (git-ignored) for local builds; Vercel environment variables `FUNDLY_*` for the web build |
| Database password | Asked for by the CLI when needed; never written down in the repository |
| Isolation check test users | `tool/cloud_checks/.env.local` (git-ignored) |
| Check tool settings | `tool/sync_probe/config.local.json` (git-ignored) |

Pinned tools: Flutter 3.47.9, Supabase CLI 3.2.0 through `npx --yes supabase@3.2.0`.
CLI v3 targets the **local** stack unless `--remote` is given.

## Compatibility policy

- **Minimum supported app version: 1.2.0 (3).** Older builds predate several
  budget accounts and cash advances and are not supported against the
  current server. Every device should run 1.2.0 or later.
- **Server changes stay additive under write protocol 1.** A new migration may
  add or relax rules, but must keep every supported app version working.
- **A breaking change** (removing or renaming a column, tightening a rule that
  existing data or a supported app relies on, a new protocol version) needs
  its own approved plan, a new minimum app version, and every device updated
  first.
- There is no forced-update check in the app (S7 Decision 3). The version on
  Profile ("Version 1.3.0 (5)") is how to tell what each device runs.
- Apps 1.2.x keep working on Personal only: the automatic stream
  `fundly_user_data` stays, and `owner_id` is set only on Personal records
  (shared spaces C2). Removing either is a breaking change.

## Releasing a change

### Order

When a change touches more than one part, deploy in this order:

1. **Back up** (see [Backups](#backups-and-recovery)): an app export and a
   `db dump`.
2. **Server migrations.** New rules must be on the server before any app that
   sends writes relying on them; otherwise those writes are refused and land
   in Refused changes.
3. **PowerSync config**, if `sync-config.yaml` changed.
4. **Web**, by pushing `main`. Every push to `main` deploys the web, so push
   app changes only once the server and sync steps above are live.
5. **iOS**, by installing the release build.

A change with no migration skips straight to step 4 or 5.

### Before deploying anything

Bump the version for every release: `version:` in `pubspec.yaml` and
`appVersion`/`appBuild` in `lib/app/app_version.dart` together (a test keeps
them equal). Then run the full local suite:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npx --yes supabase@3.2.0 db start
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private,fundly_access --fail-on warning
python3 supabase/tests/concurrency/write_api_test.py
python3 supabase/tests/concurrency/account_write_api_test.py
python3 supabase/tests/concurrency/category_plan_write_api_test.py
python3 supabase/tests/concurrency/sync_protocol_test.py
python3 supabase/tests/concurrency/dataset_import_test.py
python3 supabase/tests/concurrency/dataset_initialize_test.py
python3 supabase/tests/concurrency/space_write_api_test.py
python3 supabase/tests/client_contract_test.py
python3 supabase/tests/performance/dataset_import_timing.py
# These two reset the local database (and leave it reset, fully migrated):
python3 supabase/tests/migration/spaces_backfill_test.py
python3 supabase/tests/migration/c1_rollback_test.py
```

Everything must pass. A local schema change also needs its migration test
(CLAUDE.md §10).

### Server migrations

```sh
npx --yes supabase@3.2.0 db push --remote --dry-run
```

Stop unless the dry run lists exactly the new migration files, in order. Then:

```sh
npx --yes supabase@3.2.0 db dump --remote -f <backup folder>/YYYY-MM-DD_schema.sql
npx --yes supabase@3.2.0 db dump --remote --data-only --use-copy -f <backup folder>/YYYY-MM-DD_data.sql
npx --yes supabase@3.2.0 db push --remote
npx --yes supabase@3.2.0 db push --remote --dry-run     # must say "Remote database is up to date"
npx --yes supabase@3.2.0 db lint --remote --schema public,fundly_private,fundly_access --fail-on warning
npx --yes supabase@3.2.0 db advisors --remote
```

- Advisors should show only the 3 accepted warnings: `fundly_apply_operations`
  and `fundly_import_dataset` as SECURITY DEFINER functions for
  `authenticated` (intended), and leaked password protection off (Google
  sign-in only; S7 Decision 7).
- If the push stops part-way, nothing from the failed file is applied. Read
  the error before retrying. On 2026-11-22 a function applied by hand without
  a history row blocked the push; the fix was an approved
  `migration repair --status applied <version> --remote` after checking the
  hosted object matched the file (powersync/README.md).
- Never edit a migration that has reached the hosted project. A fix is a new
  migration.
- To confirm what is really deployed, compare a function's definition hash
  on both sides, read only:
  `db query --remote --read-only "select md5(pg_get_functiondef('<schema>.<function>(<args>)'::regprocedure))"`
  and the same with `--local`.
- Record the dry run, push, lint and advisors in the log table in
  powersync/README.md.

### PowerSync config

1. PowerSync dashboard → the Fundly instance → Sync Streams: paste
   `powersync/sync-config.yaml`, **Validate**, then **Deploy**.
2. Do not use **Reconfigure Tables**; it added extra tables to the publication
   in 2026-11. The publication is managed only by `powersync/publication.sql`
   and must list exactly `accounts`, `categories`, `custom_account_types`,
   `monthly_plans`, `transactions`, `spaces` and `space_members` (the last two
   since shared spaces C2).
3. Before deploying a sync change, rehearse it with local sync
   (`tool/sync_probe/cloud/fundly-local/`), which runs this exact file.
4. Rerun the isolation checks (below), including
   `tool/sync_probe/test/c2_space_streams_test.dart`.

### Web (Vercel)

1. Push `main`. Vercel builds with `bash tool/vercel_build.sh`, which installs
   Flutter if needed and writes the cloud settings from the Vercel
   environment variables.
2. Check the deploy is live and current:

   ```sh
   curl -s "https://fundly-budget.vercel.app/version.json?t=$(date +%s)"
   curl -sI https://fundly-budget.vercel.app/main.dart.js | grep -i cache-control   # no-cache
   curl -sI https://fundly-budget.vercel.app/sqlite3.wasm | grep -i content-type    # application/wasm
   ```

3. Open the site, check Profile shows the new version, sign in and wait for
   "Up to date". A browser still on the old version needs one reload.

### iOS (devicectl)

1. Before installing over a build with real data, export a backup from the
   app (Profile → Export backup) and copy it to the Mac.
2. Build and keep a copy, so the build can be reinstalled later:

   ```sh
   flutter build ios --release --dart-define-from-file=config/cloud.json
   mkdir -p ~/fundly-releases/<version>-<build>
   cp -R build/ios/iphoneos/Runner.app ~/fundly-releases/<version>-<build>/
   ```

3. Connect the iPhone and install over the existing app, which keeps its data:

   ```sh
   xcrun devicectl list devices
   xcrun devicectl device install app --device <device id> build/ios/iphoneos/Runner.app
   ```

4. Open the app: Profile shows the new version, the data is there, and sync
   says "Up to date".

Never delete the app to reinstall it: that wipes its signed-out data.

### Isolation checks

After a server or PowerSync change, and before a release:

```sh
set -a; . tool/cloud_checks/.env.local; set +a
python3 tool/cloud_checks/api_isolation.py                    # 15 checks
(cd tool/sync_probe && flutter test test/fundly_stream_test.dart)
```

They use the two disposable email/password test users in Supabase Auth and
remove their records afterwards (tombstones stay, by design). If the users are
gone, create two again (Authentication → Users → Add user, Auto Confirm) and
update the file.

## Rolling back

| Part | How | Watch out for |
|---|---|---|
| Web | Vercel dashboard → Deployments → the previous good deployment → **Instant Rollback** | If the release changed the local schema, a browser that already opened the new version may not open its data with the old one; signed-in data downloads again after clearing site data, signed-out browser data needs a restore |
| iOS | Install the previous build from `~/fundly-releases/` with `devicectl` | Same schema rule: an older build cannot open a database a newer build already upgraded. Then delete the app, install the older build and restore the export taken before the release |
| Server | Forward only: write and deploy a new migration that undoes the problem. For shared spaces C1 a rehearsed rollback is ready: `supabase/rollback/20261124_c1_rollback.sql` (not a migration; run as one transaction after backups, on the owner's decision) | Never edit or delete a deployed migration. A rolled-back app must still work with the server, which the compatibility policy guarantees for supported versions |
| Data | Restore a format 7 export: Profile → Restore from backup (signed in it replaces the account's data on every device, after a checkpoint export) | See [Backups and recovery](#backups-and-recovery) |

## Outages

| What happens | What you see | What to do |
|---|---|---|
| Supabase or PowerSync is down, or the network is | The app keeps working on device data; Profile shows Offline or Reconnecting, with changes waiting | Nothing. Changes upload once the service is back. Check the status pages if it lasts |
| Session expired | Sign-in needed | Sign in again; waiting changes are kept |
| Supabase project paused (free plan: **after 1 week of inactivity**) | Sync stops; sign-in fails | Supabase dashboard → the project → **Restore project** (possible for 90 days). Then check sign-in and sync on one device |
| PowerSync instance deactivated (free plan: about **1–2 weeks without deploys or client connections**) | Sync stops; device data still works | PowerSync dashboard → the instance → restart it, then **Deploy** `sync-config.yaml` again. Every device downloads everything again |
| A change keeps being refused | Profile shows "change refused · Review" | Open Refused changes, redo the change by hand if still wanted, then Dismiss. Repeated refusals for valid changes are a bug: note the reason shown |

Daily use from any device keeps both free-tier services active. Before a long
break, expect to restore them afterwards.

## Monitoring

| When | Check |
|---|---|
| After every deploy | Vercel deployment succeeded and `version.json` matches; Supabase dry run up to date, lint clean, advisors unchanged; one device signs in and shows "Up to date" |
| After a sync problem | PowerSync dashboard logs **soon**: they are kept for 24 hours only. Supabase → Logs (API, Postgres, Auth) |
| Monthly | Supabase usage: database size (free limit 500 MB; 12 MB on 2026-11-22) and egress (5 GB a month). PowerSync usage (2 GB synced a month, 500 MB hosted, 50 concurrent clients). Run the monthly backups below |

Limits are from the providers' pages read on 2026-11-22 (S7.1); recheck them
if the plans change.

## Backups and recovery

Sync is not a backup: it carries a deletion or a bad edit to every device.
Keep two kinds of backup, both outside the repository.

**App exports (format 7).** Profile → Export backup, signed in or out. Save
the file off the phone (Files, then the Mac). Do it before every iOS install
and at least monthly. Reset and Replace also make a checkpoint export
(`YYYY-MM-DD_HHmm_reset_checkpoint.json`, `…_replace_checkpoint.json`); keep
those too.

- *Recover one account's data:* sign in, Profile → Restore from backup, pick
  the file. The whole file is checked first. Signed in, it replaces the
  account's data on every device and is checked record by record afterwards.
- *Recover a device's signed-out data:* sign out, Profile → Restore from
  backup.
- A backup with several budget accounts needs app 1.2.0 or later.

**Database dumps.** Before every migration and monthly:

```sh
npx --yes supabase@3.2.0 db dump --remote -f <backup folder>/YYYY-MM-DD_schema.sql
npx --yes supabase@3.2.0 db dump --remote --data-only --use-copy -f <backup folder>/YYYY-MM-DD_data.sql
```

The data dump holds every user's records, so treat it as private. It is the
fallback when an app export is missing, or when the whole project is lost:

- *Project lost or unrecoverable:* create a new Supabase project, push all
  migrations to it, load the data dump with `psql`, then point
  `config/cloud.json`, the Vercel environment variables and PowerSync at the
  new project, and redo the Auth settings (Google provider, redirect URLs).
  This is a planned task with its own steps, not a quick fix; an app export
  restored into the new project is usually simpler for one person's data.

The free plan has no automatic daily backups or point-in-time recovery
(S7 Decision 4); Supabase Pro adds them for a fee.
