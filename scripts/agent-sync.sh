#!/usr/bin/env bash
set -Eeuo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "agent-sync: must run inside a Git repository" >&2
  exit 1
fi

BRANCH=${TASK_BRANCH:-$(git symbolic-ref --short HEAD)}
if [[ "${BRANCH}" == "main" ]]; then
  echo "agent-sync: refusing to operate directly on main" >&2
  exit 1
fi

STATUS_FILE=".agent_status"
rm -f "${STATUS_FILE}"

echo "[agent-sync] Fetching origin/main"
git fetch origin

if ! git rebase origin/main; then
  echo "[agent-sync] Rebase failed, attempting merge fallback"
  git rebase --abort || true
  git merge --no-ff origin/main || true
fi

if git ls-files -u | grep -q "Cargo.lock"; then
  echo "[agent-sync] Resolving Cargo.lock via regeneration"
  git checkout --ours Cargo.lock
  cargo generate-lockfile
  git add Cargo.lock
fi

if [[ -x ./scripts/gen.sh ]]; then
  echo "[agent-sync] Regenerating project artifacts"
  bash ./scripts/gen.sh
fi

echo "[agent-sync] Running cargo fmt"
cargo fmt --all

echo "[agent-sync] Refreshing Cargo.lock"
cargo generate-lockfile

echo "[agent-sync] Running cargo check"
cargo check --tests --benches

echo "[agent-sync] Running cargo test"
cargo test

if git status --porcelain | grep -q .; then
  echo "SYNC_PENDING_CHANGES=1" > "${STATUS_FILE}"
fi
