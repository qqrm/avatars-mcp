#!/usr/bin/env bash
# pre-task.sh
# Refresh dynamic repository assets before starting a new task.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! pre-task failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

SCRIPT_PATH="${BASH_SOURCE[0]-}"
SCRIPT_SOURCE_IS_STDIN=0
if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "-" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  cd "$SCRIPT_DIR"
else
  SCRIPT_DIR="$(pwd)"
  SCRIPT_SOURCE_IS_STDIN=1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "pre-task: must run inside a Git repository" >&2
  exit 1
fi

log() { printf '>> %s\n' "$*"; }

PAGES_BASE_URL="${PAGES_BASE_URL:-https://qqrm.github.io/codex-tools}"
AGENTS_URL="${PAGES_BASE_URL%/}/AGENTS.md"

fetch_file() {
  local url="$1"
  local dest="$2"
  local tmp
  tmp="${dest}.tmp"
  if curl -fsSL "$url" -o "$tmp"; then
    mv "$tmp" "$dest"
    log "Updated $(basename "$dest") from $url"
  else
    rm -f "$tmp"
    log "Unable to refresh $(basename "$dest") from $url"
  fi
}

fetch_file "$AGENTS_URL" "AGENTS.md"

if [ -f repo-setup.sh ]; then
  log "Executing repo-setup.sh"
  bash repo-setup.sh
fi

log "Pre-task refresh complete."
