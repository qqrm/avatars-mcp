# Base Agent Instructions

These guidelines apply to every avatar in this repository.

## Critical Checklist
- Run `./repo-setup.sh` (when provided) as soon as the repository is available, then confirm `git remote -v` points to the canonical `origin` and that `gh auth status` succeeds.
- Switch off the bootstrap `work` branch immediately, create a descriptive English feature branch, and never create or push a branch named `WORK`.
- Treat every assignment as production work: plan the solution, implement it to a high standard, and keep the working tree clean.
- Retrieve the avatar catalog via the MCP server's REST API, pick a non-default avatar that fits the task, and explain the choice in both the pull-request description and the final user summary.
- Use the `gh` CLI for pull requests—push your branch, run `gh pr create`, and wait for all mandatory GitHub Actions checks to pass (`gh pr checks` or UI) before declaring the task complete. Capture full command output for any failure.
- Run the required validation suite (`cargo fmt`, `cargo check`, `cargo clippy`, `cargo test`, `cargo machete`, etc.) before committing and again before wrapping up. Do not finish until local and remote checks are green, or you have escalated a blocker with evidence.

## Engineering Mindset
- Operate like a senior engineer: analyse the problem space, decide on a plan, execute decisively, and justify trade-offs.
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
- Keep repository automation in `repo-setup.sh` and author helpers in POSIX shell. The shared `setup.sh` bootstrapper runs `repo-setup.sh` automatically.
- If a `local_setup.sh` script exists, execute it before starting any task.
- `setup.sh` installs the `crates-mcp` server via `cargo-binstall` with a source fallback, and `mcp.json` enables it by default.
- Available local MCP servers include `crates-mcp` (e.g., `{ "tool": "search_crates", "query": "http client" }`).

## Source Control and Branching
- Treat the canonical `origin` remote as writable until a push attempt proves otherwise; do not assume restrictions without evidence.
- Create a fresh hyphenated English feature branch for every task. When a task spans multiple sessions, stay on the same branch, fetch `origin/main`, and rebase or merge **before every response**.
- Keep the task branch alive until its pull request merges—never delete, rename, or reset it mid-task, and push every new commit to the same remote branch.
- After preparing commits, run `git push --set-upstream origin <branch>` (or equivalent) before claiming that a pull request cannot be opened.
- Before reporting completion, confirm that `origin/<branch>` contains the latest commits (compare with `git log HEAD`).
- When a push or PR command fails, quote the full stderr/stdout, diagnose the cause, and propose mitigation steps instead of stopping at the first error.
- Maintain small, focused commits with clear English messages so reviewers can follow each step.
- Keep the working tree clean before requesting review or reporting status—stage intentional changes, revert stragglers, and ensure `git status` is empty when you finish.

## Development Workflow
- Treat user requests as complete tasks and deliver full pull-request solutions.
- Run every required check before committing. Default to the full test suite for the components you touched and document any skipped command with justification.
- Use automation to inspect GitHub state: rely on `gh` for pull requests, issue queries, workflow inspection, and to monitor checks.
- Use the `gh` CLI to create and manage pull requests whenever possible so CI runs early. The CLI is authenticated during container initialization and ready for immediate use.
- Ensure a writable `origin` remote is configured before invoking `gh pr create`; follow repository README guidance when the remote is missing.
- When network access or permissions block pull-request creation, record the attempted commands, explain the impact, and continue working toward the deliverable.
- The evaluation `make_pr` tool only submits metadata; it never replaces a real GitHub pull request.
- Remove dead code rather than suppressing warnings; feature-gate unused code when necessary.
- Write tests for new functionality and resolve reported problems.

## Avatars
- Use the MCP server at `https://qqrm.github.io/avatars-mcp/` to fetch avatars and base instructions.
- Use the MCP server's REST API to inspect the latest avatar catalog and README information as needed. Record HTTP errors and retry transient failures up to five times before escalating.
- Select a non-default avatar that matches the task context, document why it fits, and include this rationale both in the pull-request description and in the final response to the user.
- When automated downloads are impossible, note every attempt, escalate the outage, and choose the closest avatar based on cached knowledge while clearly labeling the fallback.
- Switch avatars through the MCP server as needed for sub-tasks (e.g., Senior, Architect, Tester, Analyst) and list every avatar used when summarising work.

## Testing and Validation
- For Rust repositories, run `cargo test` from the workspace root before opening a pull request—even when only documentation changes. Record failures verbatim and resolve them or escalate with proposed mitigation.
- Install tooling as needed (`rustup component add clippy rustfmt`).
- Standard validation sequence:
  ```bash
  cargo fmt --all
  cargo check --tests --benches
  cargo clippy --all-targets --all-features -- -D warnings
  cargo test
  cargo machete            # if available
  ```
- Skip build-heavy checks only when changes affect documentation or Markdown files, and note the justification in your report.
- Readiness requires zero formatting issues, linter warnings, or failing tests.
- Treat any failed pipeline, automated check, or test (local or remote) as a blocker—capture the logs, diagnose the root cause, and implement fixes until the suite passes before declaring the task complete.

## GitHub and CI Practices
- Treat GitHub workflows as first-class code: keep them under version control, review every change, and follow `.github/AGENTS.md` for directory-specific rules.
- Pipeline secrets reside in the `prod` environment.
- Interact with pipelines locally using [WRKFLW](https://github.com/bahdotsh/wrkflw) to validate and run workflows when needed.
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
- Keep pull requests concise: list changes, reference lines with `F:path#Lx-Ly`, and attach test results.
- In the final summary, list all avatars used and provide the link to the open pull request together with the status of every mandatory check.

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
