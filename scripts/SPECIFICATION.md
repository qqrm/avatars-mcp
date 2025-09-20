# Scripts Specification

## `agent-sync.sh`

The `agent-sync.sh` helper keeps a feature branch synchronized with `origin/main` inside constrained automation environments.
Run it from the repository root after staging local work and before handing the branch back to maintainers.

The script performs the following steps:

1. Verifies it is running inside a Git repository and refuses to operate on `main` directly.
2. Detects the target branch from `TASK_BRANCH` or the current `HEAD` and fetches the latest `origin/main` revision.
3. Attempts a `git rebase origin/main` and falls back to `git merge --no-ff origin/main` if the rebase fails.
4. Regenerates `Cargo.lock` when conflicts arise, invoking `cargo generate-lockfile` to ensure reproducible dependency graphs.
5. Recreates derived artifacts through `scripts/gen.sh` when that generator is present and executable.
6. Runs the repository validation pipeline: `cargo fmt --all`, `cargo generate-lockfile`, `cargo check --tests --benches`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test`, and `cargo machete` (when available).
7. Records pending changes in `.agent_status` so automation can detect when manual follow-up is required.

Use this helper whenever a task requires syncing with upstream without manually invoking each command, especially in environments where interactive rebases are restricted. The script exits on the first failure to preserve a clean state for further investigation.
