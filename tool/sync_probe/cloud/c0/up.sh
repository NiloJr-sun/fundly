#!/bin/sh
# Shared spaces C0: starts the local environment (Supabase stack, PowerSync and
# its storage), then writes the git-ignored config.local.json and makes sure
# the three test users in .env.local exist. Safe to run again.
set -eu
cd "$(dirname "$0")"
npx --yes supabase@3.2.0 start --workdir . >/dev/null
docker compose up -d --wait >/dev/null
npx --yes supabase@3.2.0 status --workdir . -o json 2>/dev/null | python3 -I local_env.py
