# Running the app against local sync

For reviewing app changes before they reach production (added in shared spaces
C2.3). The local Supabase stack has no Google sign-in, so
`tool/dev/local_main.dart` starts the real app and then signs in with a local
test user. It refuses any server but the local one and is never used for a
release build.

```sh
tool/sync_probe/cloud/fundly-local/up.sh
(umask 077; tool/dev/local_defines.sh A > <private dir>/fundly_local.json)
flutter run -t tool/dev/local_main.dart -d <simulator id> --dart-define-from-file=<private dir>/fundly_local.json
flutter run -t tool/dev/local_main.dart -d chrome --web-port=7361 --dart-define-from-file=<private dir>/fundly_local.json
```

The defines file holds a local test user's password: keep it outside the
repository and delete it afterwards.
