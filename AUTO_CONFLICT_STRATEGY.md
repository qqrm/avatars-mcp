# Auto-merge Conflict Strategy

This document defines the production workflow the automation agent must follow to keep feature branches synchronised with `main` and to resolve merge conflicts without human intervention. The steps below standardise configuration, conflict handling, validation, and escalation so the agent can recover from routine divergences reliably.

## 1. Baseline configuration

1. Enable conflict reuse and rebase-by-default once per machine:
   ```bash
   git config --global rerere.enabled true
   git config --global pull.rebase true
   ```
2. Honour the repository merge policies committed in `.gitattributes`. They guarantee predictable merges for generated assets (`*.snap`, `*.svg`, `target/**`, `Cargo.lock`) and enforce LF line endings for Rust sources.
3. Always work on a dedicated feature branch, keeping it active across iterations of the same task until the pull request merges. Branch names use English, hyphenated words (`feature-name-improvement`).

## 2. Required tooling scripts

| Purpose | Command |
| --- | --- |
| Full synchronisation against `main` with conflict handling and pre-flight validation | `./scripts/agent-sync.sh` |
| Commit + auto-resolve cycle that rebases, regenerates assets, and pushes the branch | `./scripts/agent-commit.sh` |

Both scripts populate `.agent_status` with diagnostic flags when automatic recovery is incomplete:
- `AUTO_CONFLICT=1` — conflicts required manual insight after automation attempts.
- `SYNC_PENDING_CHANGES=1` — sync introduced file updates that still need review/commit.
- `TESTS_FAILED=1` — at least one validation command failed.

## 3. Sync procedure (run before coding and before each commit)

1. Ensure the working tree is clean.
2. Execute `./scripts/agent-sync.sh`.
3. If `.agent_status` exists afterwards, inspect the recorded flags:
   - `SYNC_PENDING_CHANGES=1`: review the modified files locally, commit them once verified.
   - Any other flag: escalate following [Section 6](#6-escalation).

The sync script performs:
- `git fetch origin`.
- `git rebase origin/main` with an automatic fallback to `git merge --no-ff origin/main`.
- Regeneration of `Cargo.lock` if the file conflicts.
- Optional regeneration hook (`scripts/gen.sh`) for generated assets.
- Formatting via `cargo fmt --all`.
- Lockfile refresh (`cargo generate-lockfile`).
- Validation commands: `cargo check --tests --benches` and `cargo test`.

## 4. Commit procedure with conflict recovery

1. Stage your changes and run `./scripts/agent-commit.sh`.
2. The script creates a work-in-progress commit, rebases onto the latest `origin/main`, and resolves conflict classes:
   - **Formatting (`*.rs`)**: reformatted automatically with `cargo fmt --all`.
   - **Generated artifacts**: regenerated through `scripts/gen.sh` when present.
   - **`Cargo.lock`**: replaced with our regenerated version via `cargo generate-lockfile`.
3. If the post-format commit fails because conflicts persist, the script records `AUTO_CONFLICT=1` for escalation.
4. Validation commands (`cargo check --tests --benches`, `cargo test`) run after conflict resolution. Failures write `TESTS_FAILED=1`.
5. The branch is pushed with `git push -u origin HEAD` only when `.agent_status` remains absent after validation. Any recorded flag stops the script and prevents publishing broken commits.

## 5. Handling common merge scenarios

| Scenario | Automated response |
| --- | --- |
| Formatting drift | `cargo fmt --all` rewrites the files, and the script commits the formatter output. |
| Generated files out of sync | `scripts/gen.sh` is executed. Add any new generators there so automation remains aware. |
| `Cargo.lock` divergence | The script keeps our version, regenerates it, and stages the result. |
| Non-trivial refactors on `main` | Allow the rebase/merge to complete, run generators + formatter, then re-run the full validation suite. |

## 6. Escalation

When `.agent_status` contains `AUTO_CONFLICT=1` or a failing validation flag after rerunning the scripts once, the agent cannot self-heal. Perform these steps:
1. Reset the working tree to the latest commit (`git reset --hard HEAD`).
2. Generate a conflict report:
   ```text
   Conflicts:
   - <file path>
   - ...
   Hypothesis:
   - <short explanation of the divergence>
   Proposal:
   - <planned remediation>
   Patch:
   <minimal diff suggestion>
   ```
3. Apply the `needs-human` label to the pull request and attach the report.

## 7. Operational guardrails

- Keep pull requests scoped narrowly to minimise the chance of semantic conflicts.
- Do not edit files outside the feature scope; prefer duplicating helper logic if cross-module coupling would increase.
- Regenerate artifacts only through `scripts/gen.sh` so future changes automatically participate in the conflict pipeline.
- Ensure every pushed commit passes `cargo fmt`, `cargo check --tests --benches`, and `cargo test` locally before requesting review.

Following this playbook equips the automation agent to keep branches current, resolve routine merge conflicts, and escalate only when human insight is required.
