# Fundly S1 compatibility probe

Disposable Flutter package for evaluating PowerSync with Drift. It uses its own
bundle ID (`com.nilojr.probe.fundlySyncProbe`), local database filenames, package
resolution and cloud tables. It never opens Fundly's real database.

## Setup

Run commands from `tool/sync_probe/`:

```sh
flutter pub get
sh setup_web.sh
```

The script downloads assets matching the locked PowerSync SDK into this
package only. It also copies them to a package URL for Flutter's browser test
server. Generated/downloaded artifacts and `config.local.json` are ignored.
Commit `pubspec.lock` and generated Drift Dart code for repeatability.

## Local checks (no cloud account required)

```sh
flutter analyze
flutter test
flutter test --platform chrome --dart-define=PROBE_ASSET_PREFIX=/packages/fundly_sync_probe/web_assets/ test/probe_test.dart
flutter devices
flutter test integration_test/probe_test.dart -d <ios-simulator-id>
flutter build ios --simulator --debug
flutter build web
```

`flutter test` includes the real SQLite/PowerSync queue checks and one local
HTTP stand-in for RPC rejection/retry. The latter does not prove hosted SQL,
authentication, RLS, or downloads. The shared browser/device suite covers UUID
relations, transactions, rollback, durable queue reopening, watch streams,
deletion, revision tracking, CHECKs, foreign keys, and a raw-table migration.

Without configuration, `flutter run -d chrome --web-port=7358` opens a local-only
diagnostic UI. Keep that origin stable to test refresh persistence.

## Live Supabase / PowerSync setup

1. Review and run [cloud/schema.sql](cloud/schema.sql) in Supabase's SQL Editor.
   It creates only `probe_parents`, `probe_entries`, `probe_receipts`, their
   ownership policies, and the `probe_apply_batch` function. It does not create
   Fundly's production tables. SQL execution/security validation is a separate
   check from the local Dart tests.
2. In PowerSync, refresh the guided Supabase setup and select **probe_parents
   and probe_entries only**. Leave probe_receipts unchecked; it is backend-only.
   For manual setup, use the replication role/publication instructions in the
   [official guide](https://docs.powersync.com/integrations/supabase/guide).
3. Enable Supabase client authentication in PowerSync, then validate and deploy
   [cloud/sync-config.yaml](cloud/sync-config.yaml). Do not substitute an
   unfiltered `SELECT *` that sends every user's records to all clients.
4. Create two disposable email/password users in Supabase Authentication →
   Users, with email confirmed. Enter credentials directly in the probe UI;
   do not put passwords into config files or chat. This avoids configuring
   Google OAuth before its planned task. This probe does not implement signup.
5. Copy `config.example.json` to `config.local.json` and fill in the public
   endpoints and publishable key. The owner's supplied settings are already
   recorded locally. Never put privileged keys into this file.
6. Start both clients with the same config:

   ```sh
   flutter run -d chrome --web-port=7358 --dart-define-from-file=config.local.json
   flutter run -d <ios-simulator-id> --dart-define-from-file=config.local.json
   ```

Use test account A on both clients. Use a separate browser profile for account
B. The connector refuses to upload if its authenticated user changes; full
account-switch and sign-out UX belongs to S4. Stop/restart the probe to log in
again. Keep browser tabs on the same test account when checking multi-tab use.

## Live acceptance checklist (record observations, not assumptions)

- Create a pair on iOS: confirm matching IDs in Supabase and on web, with one
  parent and one child and an empty upload queue after synchronization.
- Disconnect web, create a pair, refresh/reopen while still disconnected, then
  reconnect. Verify the pair appears once on iOS. The UI connects on startup;
  to test offline reopening, disable network as well as pressing Disconnect.
- Delete a pair: confirm both records disappear on the other client and server.
- Open two tabs on the same origin/user: both should display changes without
  duplicate uploads. Record any worker/storage errors.
- Sign in as B in another browser profile: A's rows must never appear. Check
  direct Data API/RPC authorization as well as the displayed list.
- Run the intentional rejection **last**, using disposable data: press its
  button, verify a server rejection, no partial cloud pair, and retained local
  queue after restart. This prototype deliberately blocks on that rejected
  batch. It does not claim to implement production conflict recovery.
- Verify a retry after a committed response is lost does not duplicate cloud
  data (the batch receipt is designed for this; live behavior remains to prove).

The upload function is intentionally narrow: parent creation/edit/delete with
revision checks, child creation/delete, and atomic batch receipts. It is not
the production financial validation API. Do not use it for personal records.

## Cleanup

Stop both clients and remove only this probe app/browser origin's data when
finished. Never clear Fundly's app container. Keep the original local Fundly
database and backups unchanged. Remove probe Sync Streams/publication entries
before dropping these disposable cloud objects, and review cleanup SQL first.

The prototype's test accounts, receipts, and tables can remain while S1 live
verification is pending. Google sign-in and production integration are not
delivered by this package.
