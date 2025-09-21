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

MCP_BASE_URL="${MCP_BASE_URL:-https://qqrm.github.io/avatars-mcp}"
AGENTS_URL="${MCP_BASE_URL%/}/AGENTS.md"
MCP_MANIFEST_URL="${MCP_BASE_URL%/}/mcp.json"
CODEX_WORKFLOW_URL="${MCP_BASE_URL%/}/workflows/codex-cleanup.yml"
CODEX_WORKFLOW_PATH=".github/workflows/codex-cleanup.yml"

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
fetch_file "$MCP_MANIFEST_URL" "mcp.json"

ensure_codex_cleanup() {
  if [[ -f "$CODEX_WORKFLOW_PATH" ]]; then
    log "Codex cleanup workflow already present; skipping bootstrap."
    return
  fi

  local dest_dir
  dest_dir="$(dirname "$CODEX_WORKFLOW_PATH")"
  mkdir -p "$dest_dir"

  local tmp
  tmp="${CODEX_WORKFLOW_PATH}.tmp"
  if curl -fsSL "$CODEX_WORKFLOW_URL" -o "$tmp"; then
    mv "$tmp" "$CODEX_WORKFLOW_PATH"
    log "Installed Codex cleanup workflow from $CODEX_WORKFLOW_URL"
  else
    rm -f "$tmp"
    log "Unable to download Codex cleanup workflow from $CODEX_WORKFLOW_URL"
  fi
}

ensure_codex_cleanup

if [ -f repo-setup.sh ]; then
  log "Executing repo-setup.sh"
  bash repo-setup.sh
fi

log "Pre-task refresh complete."
