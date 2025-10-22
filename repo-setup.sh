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

log "Running repository setup for codex-tools"
log "Repository root: $SCRIPT_DIR"

ensure_git_repo
ensure_origin_remote
print_status
warn_branch_name

log "Setup completed at $(date --iso-8601=seconds)"
