#!/usr/bin/env bash
# Refresh lightweight state on a cached container before starting a task.
#
# Steps performed:
# 1. Normalize the working directory and ensure the script runs inside a Git repository.
# 2. Load shared bootstrap helpers to reuse refresh utilities.
# 3. Define the GitHub Pages source for shared instructions.
# 4. Download the latest AGENTS.md into the workspace and run the repository setup hook.
# 5. Emit status messages once the refresh finishes.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! refresh-cached-container failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

SCRIPT_PATH="${BASH_SOURCE[0]-}"
if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "-" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  if [[ -f "$SCRIPT_DIR/../scripts/lib/container-bootstrap-common.sh" ]]; then
    cd "$SCRIPT_DIR/.."
  fi
fi

if [[ -n "${CODEX_TOOLS_BOOTSTRAP_LIB:-}" ]]; then
  # shellcheck disable=SC1090
  source "$CODEX_TOOLS_BOOTSTRAP_LIB"
else
  source "scripts/lib/container-bootstrap-common.sh"
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf 'refresh-cached-container: must run inside a Git repository.\n' >&2
  exit 1
fi

PAGES_BASE_URL="${PAGES_BASE_URL:-https://qqrm.github.io/codex-tools}"
AGENTS_URL="${PAGES_BASE_URL%/}/AGENTS.md"

bootstrap_log "Refreshing cached container state"
bootstrap_refresh_pages_asset "$AGENTS_URL" "AGENTS.md"
bootstrap_run_repo_setup
bootstrap_log "Refresh complete."
