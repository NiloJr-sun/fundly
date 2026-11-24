#!/bin/sh
# Stops local PowerSync (and its storage). The Supabase stack keeps running;
# stop it with `npx --yes supabase@3.2.0 stop` from the repository root.
set -eu
cd "$(dirname "$0")"
docker compose down --volumes
