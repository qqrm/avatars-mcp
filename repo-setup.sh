#!/usr/bin/env bash
# Repository-specific initialization for avatars-mcp
# Configures the writable origin remote expected by repository tooling.

set -Eeuo pipefail

log() { printf '>> %s\n' "$*"; }

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

REMOTE_URL="${REPO_REMOTE_URL:-https://github.com/qqrm/avatars-mcp.git}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  die "Not inside a Git repository"
fi

current_remote="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "$current_remote" ]]; then
  git remote add origin "$REMOTE_URL"
  log "git remote origin added: $REMOTE_URL"
elif [[ "$current_remote" != "$REMOTE_URL" ]]; then
  git remote set-url origin "$REMOTE_URL"
  log "git remote origin updated: $REMOTE_URL"
else
  log "git remote origin already set to $REMOTE_URL"
fi

git fetch origin --tags --quiet
log "git remote origin fetched"
