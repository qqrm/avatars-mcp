#!/usr/bin/env bash
set -Eeuo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "agent-commit: must run inside a Git repository" >&2
  exit 1
fi

BRANCH=${TASK_BRANCH:-$(git symbolic-ref --short HEAD)}
if [[ "${BRANCH}" == "main" ]]; then
  echo "agent-commit: refusing to operate directly on main" >&2
  exit 1
fi

TASK_ID=${TASK_ID:-${BRANCH//[^A-Za-z0-9]/-}}
STATUS_FILE=".agent_status"
rm -f "${STATUS_FILE}"

record_status() {
  local flag=$1
  printf '%s\n' "${flag}" >>"${STATUS_FILE}"
}

git add -A
if git diff --cached --quiet; then
  echo "agent-commit: nothing staged, exiting"
  exit 0
fi

COMMIT_MSG=${COMMIT_MSG:-"task:${TASK_ID} work-in-progress"}
git commit -m "${COMMIT_MSG}"

git fetch origin
if ! git rebase origin/main; then
  echo "[agent-commit] Rebase failed, attempting merge fallback"
  git rebase --abort || true
  git merge --no-ff origin/main || true
fi

if git ls-files -u | grep -q "Cargo.lock"; then
  echo "[agent-commit] Resolving Cargo.lock via regeneration"
  git checkout --ours Cargo.lock
  cargo generate-lockfile
  git add Cargo.lock
fi

if [[ -x ./scripts/gen.sh ]]; then
  echo "[agent-commit] Regenerating project artifacts"
  bash ./scripts/gen.sh
  git add -A
fi

echo "[agent-commit] Running cargo fmt"
cargo fmt --all

git add -A

if git diff --cached --quiet; then
  echo "[agent-commit] No formatter or generator updates detected"
else
  if ! git -c rerere.enabled=true commit -m "task:${TASK_ID} auto-resolve and rebase on main"; then
    record_status "AUTO_CONFLICT=1"
  fi
fi

echo "[agent-commit] Running cargo check"
if ! cargo check --tests --benches; then
  record_status "TESTS_FAILED=1"
fi

echo "[agent-commit] Running cargo test"
if ! cargo test; then
  record_status "TESTS_FAILED=1"
fi

if [[ -f "${STATUS_FILE}" ]]; then
  echo "[agent-commit] Skipping push due to recorded failures:"
  cat "${STATUS_FILE}"
  exit 1
fi

git push -u origin HEAD
