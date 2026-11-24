#!/bin/sh
# Shared spaces C0: stops the local environment. With --wipe, also deletes its
# data (C0 Supabase database, PowerSync storage) and the test users file.
set -eu
cd "$(dirname "$0")"
if [ "${1:-}" = "--wipe" ]; then
  docker compose down --volumes
  npx --yes supabase@3.2.0 stop --workdir . --no-backup
  rm -f .env.local config.local.json
else
  docker compose down
  npx --yes supabase@3.2.0 stop --workdir .
fi
