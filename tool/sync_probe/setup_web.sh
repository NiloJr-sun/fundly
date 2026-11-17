#!/bin/sh
set -eu
cd "$(dirname "$0")"
dart run powersync:setup_web
mkdir -p lib/web_assets
cp web/sqlite3.wasm web/powersync_db.worker.js lib/web_assets/
