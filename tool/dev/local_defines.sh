#!/bin/sh
# Prints the --dart-define-from-file JSON for tool/dev/local_main.dart from the
# local sync files (tool/sync_probe/cloud/fundly-local, run up.sh first).
# Usage: tool/dev/local_defines.sh [A|B] > <private file>   (chmod 600; never commit)
set -eu
cd "$(dirname "$0")/../sync_probe/cloud/fundly-local"
. ./.env.local
USER_LETTER=${1:-A} python3 -I -c '
import json, os
config = json.load(open("config.local.json"))
letter = os.environ["USER_LETTER"]
print(json.dumps({
    "FUNDLY_SUPABASE_URL": config["SUPABASE_URL"],
    "FUNDLY_SUPABASE_PUBLISHABLE_KEY": config["SUPABASE_PUBLISHABLE_KEY"],
    "FUNDLY_POWERSYNC_URL": config["POWERSYNC_URL"],
    "FUNDLY_DEV_EMAIL": os.environ[f"FUNDLY_TEST_{letter}_EMAIL"],
    "FUNDLY_DEV_PASSWORD": os.environ[f"FUNDLY_TEST_{letter}_PASSWORD"],
}))'
