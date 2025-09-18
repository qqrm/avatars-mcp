#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
  printf '>> %s\n' "$*"
}

warn() {
  printf '!! %s\n' "$*" >&2
}

LOG_FILE="notes/setup_log.md"
if [[ ! -f "$LOG_FILE" ]]; then
  cat <<'LOGHDR' > "$LOG_FILE"
# Repository Setup Log

This log captures timestamps of successful `repo-setup.sh` executions.
LOGHDR
fi

origin_url="missing"
if git remote get-url origin >/dev/null 2>&1; then
  origin_url="$(git remote get-url origin)"
  log "origin remote detected: $origin_url"
else
  warn "origin remote is not configured. Use 'git remote add origin <url>' before creating pull requests."
fi

now_ts="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
printf '\n- %s – repo-setup.sh executed. origin: %s\n' "$now_ts" "$origin_url" >> "$LOG_FILE"

log "Setup complete at $now_ts"
