#!/usr/bin/env bash
# Bootstrap a cached development container with persistent tooling and GitHub auth.
#
# Steps performed:
# 1. Normalize the working directory so helper scripts resolve relative paths.
# 2. Load the shared bootstrap helpers from scripts/lib/container-bootstrap-common.sh.
# 3. Verify required environment variables (GH_TOKEN) and optional configuration.
# 4. Install GitHub CLI, Rust toolchain, cargo-binstall, and developer tools.
# 5. Persist GitHub authentication in the container and validate saved credentials.
# 6. Confirm repository access, uninstall GH_TOKEN from the environment, and install the Codex cleanup workflow.
# 7. Print example commands that rely on the cached auth and remind about the refresh script.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! bootstrap-split-initialization-cached-base failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

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

bootstrap_log "Bootstrapping cached base initialization"
bootstrap_require_env GH_TOKEN
: "${GH_HOST:=github.com}"
CHECK_REPO="${CHECK_REPO:-}"

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

bootstrap_log "Auth persisted. Example checks without GH_TOKEN:"
bootstrap_log "  env -u GH_TOKEN gh repo view cli/cli --json name,description | jq"
bootstrap_log "  env -u GH_TOKEN gh run list -R ${CHECK_REPO:-owner/repo} -L 5 || true"

bootstrap_log "Cached base initialization complete. Run scripts/split-initialization-pretask.sh before each task."
