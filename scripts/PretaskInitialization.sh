#!/usr/bin/env bash
# PretaskInitialization refreshes lightweight state on a cached container before starting a task.
#
# The helper downloads updated instructions without sourcing external
# libraries.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! PretaskInitialization failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

bootstrap_log() {
  printf '>> %s\n' "$*"
}

bootstrap_refresh_pages_asset() {
  local url="$1"
  local dest="$2"
  local tmp

  tmp="${dest}.tmp"
  if curl -fsSL "$url" -o "$tmp"; then
    mv "$tmp" "$dest"
    bootstrap_log "Updated $(basename "$dest") from $url"
  else
    rm -f "$tmp"
    bootstrap_log "Unable to refresh $(basename "$dest") from $url"
  fi
}

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf 'PretaskInitialization: must run inside a Git repository.\n' >&2
  exit 1
fi

PAGES_BASE_URL="${PAGES_BASE_URL:-https://qqrm.github.io/codex-tools}"
AGENTS_URL="${PAGES_BASE_URL%/}/AGENTS.md"

bootstrap_log "Refreshing pretask state for cached containers"
bootstrap_refresh_pages_asset "$AGENTS_URL" "AGENTS.md"
bootstrap_log "Pretask refresh complete."
