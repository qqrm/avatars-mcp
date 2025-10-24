#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
  printf '>> %s\n' "$*"
}

ensure_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    printf 'Error: repo-setup.sh must run inside a Git repository.\n' >&2
    exit 1
  fi
}

ensure_origin_remote() {
  local canonical_remote="https://github.com/qqrm/codex-tools.git"

  if git remote get-url origin >/dev/null 2>&1; then
    local current_url
    current_url="$(git remote get-url origin)"
    if [[ "$current_url" != "$canonical_remote" ]]; then
      log "Updating origin remote from ${current_url} to ${canonical_remote}"
      git remote set-url origin "$canonical_remote"
    else
      log "Origin remote already points to ${canonical_remote}"
    fi
  else
    log "Configuring origin remote: ${canonical_remote}"
    git remote add origin "$canonical_remote"
  fi
}

print_status() {
  log "Current git status:"
  git status --short
  log "Configured remotes:"
  git remote -v
}

warn_branch_name() {
  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$current_branch" == "work" ]]; then
    printf 'Warning: Branch "work" is reserved for bootstrapping. Create a descriptive feature branch before making changes.\n' >&2
  fi
}

run_step() {
  local description="$1"
  shift
  log "$description"
  "$@"
}

run_cargo_step() {
  local description="$1"
  shift
  run_step "$description" cargo "$@"
}

PAGES_TMP_DIR=""

cleanup_pages_tmp() {
  if [[ -n "$PAGES_TMP_DIR" && -d "$PAGES_TMP_DIR" ]]; then
    rm -rf "$PAGES_TMP_DIR"
  fi
  PAGES_TMP_DIR=""
}

trap cleanup_pages_tmp EXIT

run_rust_checks() {
  if [[ ! -f Cargo.toml ]]; then
    log "Skipping Rust setup (Cargo.toml not found)"
    return
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    log "Skipping Rust setup (cargo not available)"
    return
  fi

  run_cargo_step "Fetching Rust dependencies" fetch --locked
  run_cargo_step "Formatting Rust workspace" fmt --all
  run_cargo_step "Checking Rust workspace" check --tests --benches
  run_cargo_step "Running clippy linting" clippy --all-targets --all-features -- -D warnings
  run_cargo_step "Executing Rust tests" test

  if command -v cargo-machete >/dev/null 2>&1; then
    run_cargo_step "Validating dependencies with cargo machete" machete
  else
    log "Skipping cargo machete (cargo-machete not installed)"
  fi
}

run_pages_checks() {
  if [[ ! -x ./scripts/build-pages.sh || ! -x ./scripts/validate-pages.sh ]]; then
    log "Skipping pages artifact validation (scripts missing)"
    return
  fi

  PAGES_TMP_DIR="$(mktemp -d)"
  run_step "Building GitHub Pages artifact" ./scripts/build-pages.sh "$PAGES_TMP_DIR"
  run_step "Validating GitHub Pages artifact" ./scripts/validate-pages.sh "$PAGES_TMP_DIR"
  cleanup_pages_tmp
}

log "Running repository setup for codex-tools"
log "Repository root: $SCRIPT_DIR"

ensure_git_repo
ensure_origin_remote
print_status
warn_branch_name

run_rust_checks
run_pages_checks

log "Setup completed at $(date --iso-8601=seconds)"
