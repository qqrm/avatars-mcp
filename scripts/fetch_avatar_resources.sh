#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://qqrm.github.io/avatars-mcp}"
AVATAR_JSON_PATH="${AVATAR_JSON_PATH:-/tmp/avatars.json}"
AVATAR_GUIDE_PATH="${AVATAR_GUIDE_PATH:-/tmp/avatar_guidelines.md}"
MAX_ATTEMPTS=${MAX_ATTEMPTS:-5}
SLEEP_SECONDS=${SLEEP_SECONDS:-8}

log() {
  printf '>> %s\n' "$*"
}

error() {
  printf '!! %s\n' "$*" >&2
}

json_url="${BASE_URL%/}/avatars.json"
readme_url="${BASE_URL%/}/README.md"

attempt=1
while (( attempt <= MAX_ATTEMPTS )); do
  log "Attempt ${attempt}/${MAX_ATTEMPTS} downloading $json_url"
  if curl --fail --silent --show-error "$json_url" -o "$AVATAR_JSON_PATH"; then
    log "avatars.json downloaded to $AVATAR_JSON_PATH"
    if curl --fail --silent --show-error "$readme_url" -o "$AVATAR_GUIDE_PATH"; then
      log "README.md downloaded to $AVATAR_GUIDE_PATH"
      exit 0
    else
      error "Failed to download $readme_url"
    fi
  else
    error "Failed to download $json_url"
  fi

  if (( attempt < MAX_ATTEMPTS )); then
    log "Sleeping ${SLEEP_SECONDS}s before next retry"
    sleep "$SLEEP_SECONDS"
  fi
  ((attempt++))
done

error "Unable to download avatar resources after ${MAX_ATTEMPTS} attempts"
exit 1
