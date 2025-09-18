#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="https://qqrm.github.io/avatars-mcp"
AVATAR_JSON="${1:-/tmp/avatars.json}"
GUIDELINES_MD="${2:-/tmp/avatar_guidelines.md}"
MAX_ATTEMPTS=5
SLEEP_SECONDS=10

attempt=1
while (( attempt <= MAX_ATTEMPTS )); do
  if curl --fail --silent --show-error "${BASE_URL}/avatars.json" -o "$AVATAR_JSON"; then
    curl --fail --silent --show-error "${BASE_URL}/README.md" -o "$GUIDELINES_MD"
    printf 'Fetched avatar data on attempt %d.\n' "$attempt"
    exit 0
  fi
  printf 'Attempt %d failed, retrying in %d seconds...\n' "$attempt" "$SLEEP_SECONDS" >&2
  attempt=$(( attempt + 1 ))
  sleep "$SLEEP_SECONDS"
done

printf 'Failed to download avatar resources after %d attempts.\n' "$MAX_ATTEMPTS" >&2
exit 1
