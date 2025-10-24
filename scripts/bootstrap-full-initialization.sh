#!/usr/bin/env bash
# Bootstrap a fresh, non-cached container with all tooling and repository assets.
#
# Steps performed:
# 1. Normalize the working directory for consistent relative path handling.
# 2. Load the shared bootstrap helpers from scripts/lib/container-bootstrap-common.sh.
# 3. Verify required environment variables (GH_TOKEN) and resolve optional configuration values.
# 4. Install GitHub CLI, Rust toolchain, cargo-binstall, and developer tools.
# 5. Persist GitHub authentication, validate the stored credentials, and check repository access.
# 6. Ensure the Codex cleanup workflow is installed for the repository.
# 7. Refresh AGENTS.md from GitHub Pages and run the repository-specific setup script.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! bootstrap-full-initialization failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

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

bootstrap_log "Performing full container initialization"
bootstrap_require_env GH_TOKEN
: "${GH_HOST:=github.com}"
CHECK_REPO="${CHECK_REPO:-}"
PAGES_BASE_URL="${PAGES_BASE_URL:-https://qqrm.github.io/codex-tools}"
AGENTS_URL="${PAGES_BASE_URL%/}/AGENTS.md"

bootstrap_prepare_paths
bootstrap_ensure_gh_cli
bootstrap_ensure_rust_toolchain
bootstrap_ensure_cargo_binstall
bootstrap_ensure_dev_tools
bootstrap_persist_gh_auth
bootstrap_validate_saved_auth
bootstrap_validate_repo_access "$CHECK_REPO"
unset GH_TOKEN

bootstrap_ensure_codex_cleanup_workflow
bootstrap_refresh_pages_asset "$AGENTS_URL" "AGENTS.md"
bootstrap_run_repo_setup

bootstrap_log "Full initialization complete."
