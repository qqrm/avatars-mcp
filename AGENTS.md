# Base Agent Instructions

These guidelines apply to every avatar in this repository.

## Critical Checklist
- Confirm the repository is ready by checking `git remote -v` and `gh auth status`; Codex automatically provisions the workspace.
- Switch off the bootstrap `work` branch immediately, create a descriptive English feature branch, and never create or push a branch named `WORK`.
- Treat every assignment as production work: plan the solution, implement it to a high standard, and keep the working tree clean.
- Retrieve the avatar catalog via the MCP server's REST API, pick a non-default avatar that fits the task, and explain the choice in the final user summary and maintainer notes.
- Before starting substantive work, inspect remote branches with `gh`, delete temporary feature branches older than 48 hours, and close associated pull requests so the namespace stays clean. Never attempt to delete protected branches such as `main`, `develop`, or release branches. Example commands:
  ```bash
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  gh api repos/${repo}/branches --paginate \
    --jq '.[]
      | select(.name | test("^(main|master|develop|prod|production|stable|release($|[-/_0-9].*))$"; "i") | not)
      | select((now - (.commit.committer.date | fromdateiso8601)) > 172800)
      | "\(.name)\t\(.commit.committer.date)"'
  gh pr close <number> --delete-branch
  # Only delete confirmed temporary feature branches:
  gh api repos/${repo}/git/refs/heads/<branch> -X DELETE
  # Optional: when the `gh-branch` extension is installed (gh extension install mislav/gh-branch)
  gh branch delete <branch> --remote
  ```
- Mirror GitHub Actions locally: inspect recent workflow runs with `gh` and execute the required pipelines with `wrkflw` (for example, `wrkflw validate` and `wrkflw run .github/workflows/<workflow>.yml`). Do **not** create pull requests—maintainers open them manually via Codex after review.
- Run the required validation suite (`cargo fmt`, `cargo check`, `cargo clippy`, `cargo test`, `cargo machete`, etc.) before committing and again before wrapping up. Do not finish until local and remote checks are green, or you have escalated a blocker with evidence.

## Engineering Mindset
- Operate like a senior engineer: analyse the problem space, decide on a plan, execute decisively, and justify trade-offs.
- Engineer solutions that achieve the goal with the minimum necessary, high-quality code—favor efficient, well-considered designs over verbose implementations.
- Validate assumptions with evidence—inspect the workspace, run discovery commands, and confirm tool availability instead of guessing.
- Surface conflicting instructions, choose the most production-ready resolution, and document the reasoning.
- Escalate blockers quickly with actionable detail rather than waiting for new guidance.

## Planning and Strategy
- Review every applicable `AGENTS.md` file before modifying code.
- Consult repository documentation such as `ARCHITECTURE.md`, `SPECIFICATION.md`, or READMEs whenever they exist.
- Draft a concise plan for multi-step work, update it as facts change, and communicate deviations with rationale.
- Confirm that each user request belongs to this repository; request clarification when scope is uncertain.
- Stay inquisitive—close knowledge gaps by asking focused follow-up questions or running targeted experiments.

## Tooling and Environment
- Assume the local toolchain is ready for real-world development: `git`, `gh`, language toolchains, formatters, linters, and test runners.
- Prefer command-line tooling and automate repetitive steps to keep workflows reproducible.
- Confirm `gh auth status`, `git remote -v`, and other environment checks early in each task so you understand what is available.
- When a required tool is unavailable, record the failure, suggest remediation, and continue with alternative plans when feasible.
- Codex bootstrap scripts install shared tooling (including `wrkflw`) automatically; raise an incident only if required commands are missing.
- Available local MCP servers include `crates-mcp` (e.g., `{ "tool": "search_crates", "query": "http client" }`).

## Source Control and Branching
- Treat the canonical `origin` remote as writable until a push attempt proves otherwise; do not assume restrictions without evidence.
- Create a fresh hyphenated English feature branch for every task. When a task spans multiple sessions, stay on the same branch, fetch `origin/main`, and rebase or merge **before every response**.
- Keep the task branch alive until maintainers confirm integration—never delete, rename, or reset it mid-task, and push every new commit to the same remote branch.
- After preparing commits, push the branch to `origin` (for example, `git push --set-upstream origin <branch>`). Escalate immediately if the push fails.
- Before reporting completion, confirm that `origin/<branch>` contains the latest commits (compare with `git log HEAD`).
- When a push or GitHub command fails, quote the full stderr/stdout, diagnose the cause, and propose mitigation steps instead of stopping at the first error.
- Maintain small, focused commits with clear English messages so reviewers can follow each step.
- Keep the working tree clean before requesting review or reporting status—stage intentional changes, revert stragglers, and ensure `git status` is empty when you finish.

## Development Workflow
- Treat user requests as complete tasks and deliver production-ready branches that maintainers can promote without extra fixes.
- Run every required check before committing. Default to the full test suite for the components you touched and document any skipped command with justification.
- Use automation to inspect GitHub state: rely on `gh` for issue triage and workflow history, and keep `wrkflw` runs aligned with the GitHub Actions checks enforced on the repository.
- Surface any blockers preventing a clean branch handoff (failed checks, diverged history, etc.) together with remediation steps.
- Do not open pull requests. Once the branch is ready and checks are green, hand off the context so maintainers can create the PR manually via Codex.
- Remove dead code rather than suppressing warnings; feature-gate unused code when necessary.
- Write tests for new functionality and resolve reported problems.

## Avatars
- Use the MCP server at `https://qqrm.github.io/avatars-mcp/` to fetch avatars and base instructions.
- Use the MCP server's REST API to inspect the latest avatar catalog and README information as needed. Record HTTP errors and retry transient failures up to five times before escalating.
- Select a non-default avatar that matches the task context, document why it fits, and include this rationale in the final response to the user and in maintainer notes when requested.
- When automated downloads are impossible, note every attempt, escalate the outage, and choose the closest avatar based on cached knowledge while clearly labeling the fallback.
- Switch avatars through the MCP server as needed for sub-tasks (e.g., Senior, Architect, Tester, Analyst) and list every avatar used when summarising work.

## Testing and Validation
- For Rust repositories, run `cargo test` from the workspace root even when only documentation changes. Record failures verbatim and resolve them or escalate with proposed mitigation.
- Install tooling as needed (`rustup component add clippy rustfmt`).
- Standard validation sequence:
  ```bash
  cargo fmt --all
  cargo check --tests --benches
  cargo clippy --all-targets --all-features -- -D warnings
  cargo test
  cargo machete            # if available
  ```
- Treat every failure or warning from the required tooling—including findings such as unused dependencies reported by `cargo machete`—as part of the active task and resolve them before finishing, even when the issue originates outside the immediate scope of the requested change.
- Skip build-heavy checks only when changes affect documentation or Markdown files, and note the justification in your report.
- Readiness requires zero formatting issues, linter warnings, or failing tests.
- Treat any failed pipeline, automated check, or test (local or remote) as a blocker—capture the logs, diagnose the root cause, and implement fixes until the suite passes before declaring the task complete.

## GitHub and CI Practices
- Treat GitHub workflows as first-class code: keep them under version control, review every change, and follow `.github/AGENTS.md` for directory-specific rules.
- Pipeline secrets reside in the `prod` environment.
- Run GitHub Actions workflows locally with [WRKFLW](https://github.com/bahdotsh/wrkflw) before handing off a branch. Typical commands:
  ```bash
  wrkflw validate
  wrkflw run .github/workflows/<workflow>.yml
  ```
- Use the GitHub interface to inspect logs from the five most recent pipeline runs.
- Prefer the [`dtolnay/rust-toolchain`](https://github.com/dtolnay/rust-toolchain) pipelines for Rust projects—they are our required standard.
- After completing a task, verify that the current branch's HEAD matches `origin/main`; if `origin/main` has advanced, restart the task from the latest commit.

## Instruction Management
- This root `AGENTS.md` is fetched from a remote server during container initialization. Update it only when you intentionally change the global rules.
- Repository-specific instructions may appear in `REPO_AGENTS.md`. If this file is absent, assume no extra instructions.
- Additional `AGENTS.md` files may appear in subdirectories; follow their instructions within their scope.
- Keep `AGENTS.md` entries in English.

## Communication
- Replies to users must be concise and in **Russian**.
- Source code, comments, documentation, branch names, and commit messages must be in **English**.
- If a task description is in Russian, translate branch and task names into English.
- Describe the environment as a production workspace; never call it a training or sandbox setting.
- Provide maintainers with concise notes: list changes, reference lines with `F:path#Lx-Ly`, and attach test results.
- In the final summary, list all avatars used and report the status of every mandatory check you reproduced locally.

## Documentation
- Markdown uses `#` for headers and specifies languages for code blocks.
- Markdown filenames must be ALL_CAPS with underscores between words.
- Comments and documentation are always in English.

## Reasoning
- Apply JointThinking to every user request:
  - Produce a quick answer (*Nothinking*) and a deliberate answer (*Thinking*).
  - If both answers match, return the *Thinking* version.
  - If they differ, analyse both and output a revised *Thinking* response.
- Formatting example:
  ```
  [Nothinking] fast answer
  [Thinking] detailed answer

  [Thinking:revision] refined answer
  ```
