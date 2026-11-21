#!/usr/bin/env bash
# Builds the Flutter web app on Vercel with the cloud config.
#
# config/cloud.json is git-ignored, so the same values come from the Vercel
# project's environment variables (all public values that ship inside the
# app) and are written to build/vercel_cloud.json; config/cloud.json is never
# touched. If none are set, the build is local-only, like a build without it.
#
# Vercel build command: bash tool/vercel_build.sh
# (keep any Flutter install steps before it, joined with &&).
set -euo pipefail

cd "$(dirname "$0")/.."

keys=(
  FUNDLY_SUPABASE_URL
  FUNDLY_SUPABASE_PUBLISHABLE_KEY
  FUNDLY_GOOGLE_WEB_CLIENT_ID
  FUNDLY_GOOGLE_IOS_CLIENT_ID
)

missing=()
for key in "${keys[@]}"; do
  value="${!key:-}"
  if [[ -z "$value" ]]; then
    missing+=("$key")
  elif [[ "$value" == *'"'* || "$value" == *'\'* ]]; then
    echo "error: $key contains a quote or backslash" >&2
    exit 1
  fi
done

if [[ ${#missing[@]} -eq ${#keys[@]} ]]; then
  echo "No FUNDLY_* variables set: building local-only (no sign-in)."
  flutter build web --release
  exit 0
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "error: missing ${missing[*]}" >&2
  exit 1
fi

config=build/vercel_cloud.json
mkdir -p build
{
  echo '{'
  for i in "${!keys[@]}"; do
    key="${keys[$i]}"
    separator=','
    [[ $i -eq $((${#keys[@]} - 1)) ]] && separator=''
    printf '  "%s": "%s"%s\n' "$key" "${!key}" "$separator"
  done
  echo '}'
} > "$config"

echo "Building with cloud config for ${FUNDLY_SUPABASE_URL}."
flutter build web --release --dart-define-from-file="$config"
