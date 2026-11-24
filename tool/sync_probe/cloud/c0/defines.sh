#!/bin/sh
# Shared spaces C0: prints the test users in .env.local as a JSON object for
# --dart-define-from-file (on-device and browser tests cannot read the
# environment). Redirect it to a chmod 600 file outside the repository.
set -eu
cd "$(dirname "$0")"
. ./.env.local
python3 -I -c '
import json, os
names = [f"C0_TEST_{u}_{k}" for u in "ABC" for k in ("EMAIL", "PASSWORD")]
print(json.dumps({n: os.environ[n] for n in names}))'
