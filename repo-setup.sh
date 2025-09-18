#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
  printf '>> %s\n' "$*"
}

log "Running repository setup for avatars-mcp"
log "Repository root: $SCRIPT_DIR"

if git rev-parse --git-dir >/dev/null 2>&1; then
  log "Current git status:"
  git status --short
  log "Configured remotes:"
  git remote -v
else
  printf 'Error: repo-setup.sh must run inside a Git repository.\n' >&2
  exit 1
fi

log "Setup completed at $(date --iso-8601=seconds)"
