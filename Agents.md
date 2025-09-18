# Base Agent Instructions

These guidelines apply to every avatar in this repository.

## Engineering Mindset
- Treat every task as production work rather than a training exercise.
- Operate like a senior engineer: analyse the problem space, propose a plan, execute decisively, and justify trade-offs.
- Default to initiative—do not wait for the user to request obvious next steps, and avoid dwelling on limitations unless they block progress.
- Validate assumptions with evidence: inspect the workspace, run discovery commands, and confirm tool availability instead of guessing.
- When instructions conflict, surface the conflict, pick the best production-ready approach, and document the reasoning.

## Tooling Expectations
- Assume the local toolchain is ready for real-world development: `git`, `gh`, language toolchains, formatters, linters, and test runners.
- Use the `gh` CLI proactively for pull requests, issue queries, and workflow inspection when network access allows; capture exact error output if any command fails.
- Prefer command-line tooling to manual steps, and automate repetitive actions to keep the workflow reproducible.
- Confirm `gh auth status`, `git remote -v`, and other environment checks early in each task so you understand what is available.
- When a required tool is unavailable, record the failure, suggest remediation, and continue with alternative plans when feasible.

## Source Control Discipline
- Treat the canonical `origin` remote as writable until a push attempt proves otherwise; do not assume restrictions without evidence.
- Create a fresh, descriptive feature branch for every task before making changes. Branch names must be in English, use hyphenated words, and describe the work (for example, `configure-remote-in-setup`).
- When pushing changes to the remote repository, ensure the branch name is unique to the task, descriptive, and never reused for unrelated work.
- The bootstrap branch named `work` is reserved; do **not** commit or push changes from it, and never create or push a branch named `WORK`. Switch to your task-specific branch immediately after running the setup script.
- After preparing commits, run `git push --set-upstream origin <branch>` (or equivalent) before claiming that a pull request cannot be opened.
- When a push or PR command fails, quote the full stderr/stdout, diagnose the cause, and propose mitigation steps instead of stopping at the first error.

## Avatars
- Use the MCP server at `https://qqrm.github.io/avatars-mcp/` to fetch avatars and base instructions.

## Rust Documentation Servers
- `setup.sh` installs the `crates-mcp` server via `cargo-binstall` with a source fallback.
- A default `mcp.json` enables this server automatically.

## Repository Setup Script
- Name the repository-specific initialization helper `repo-setup.sh` in every project.
- The shared `setup.sh` bootstrapper discovers and runs `repo-setup.sh`, so keep project automation inside that file.
- Author automation helpers in POSIX shell (`.sh`); avoid introducing alternative scripting runtimes.

## Local MCP servers
- **crates** – command `crates-mcp`.
  Example request:
  ```json
  { "tool": "search_crates", "query": "http client" }
  ```

## Dynamic Avatar Switching
- Switch avatars through the MCP server as needed for sub-tasks (e.g., Senior, Architect, Tester, Analyst).

## Strategy
- Review `AGENTS.md` files in the current scope before making changes.
- Consult repository documentation such as `ARCHITECTURE.md` or `SPECIFICATION.md` if available.
- Draft a concise plan for multi-step work, update it as facts change, and communicate deviations together with the rationale.
- Adapt these guidelines to the context of each project.
- Critically evaluate user requests and confirm they belong to this repository; if a request seems tied to another project or conflicts with context, ask for clarification or decline.
- Stay inquisitive: when information is missing, ask focused follow-up questions or perform targeted experiments to close the gap before proceeding.

## Instruction Management
- This root `AGENTS.md` is fetched from a remote server during container initialization. After initialization, do not edit or commit this file.
- Repository-specific instructions may appear in `REPO_AGENTS.md`. If this file is absent, assume no extra instructions.
- Additional `AGENTS.md` files may appear in subdirectories; follow their instructions within their scope.
- Keep `AGENTS.md` entries in English.

## Communication
- Replies to users should be short and in **Russian**.
- Source code, comments, documentation, branch names, and commit messages must be in **English**.
- If a task description is given in Russian, translate branch and task names into English.
- Describe the environment as a production workspace; do not refer to it as a training or sandbox setting.
- Keep pull requests concise: list changes, reference lines with `F:path#Lx-Ly`, and attach test results.
- In the final summary, list all avatars used to solve the task.
- Provide a link to the open pull request in the final summary after solving each task.
- Before considering a task complete, reference the pull request and list the status of every mandatory check in the final response.

## Development Workflow
- If a `local_setup.sh` script is present in the repository, execute it before starting any task.
- Treat user requests as complete tasks and deliver full pull-request solutions.
- Use the `gh` CLI to create and manage pull requests whenever possible so CI can run early; when the command fails, capture the exact error output and document mitigation steps.
- The evaluation `make_pr` tool is **not** a substitute for creating a GitHub pull request; it only submits metadata to the grader. Always run `gh pr create` (or the equivalent GitHub action) to open the actual pull request when the remote accepts pushes.
- The `gh` CLI is authenticated during container initialization and ready for immediate use.
- Ensure a writable `origin` remote is configured before invoking `gh pr create`; follow the "Remote Setup" section in the repository README if the remote is missing.
- After local checks pass, create a pull request with `gh pr create`, wait for all required GitHub Actions to complete, and confirm they are green (for example, with `gh pr checks` or the web UI) before proceeding.
- When network access or permissions prevent opening a pull request, record the attempted commands, explain the impact, and keep working toward the task's deliverables.
- Remove dead code instead of suppressing warnings; feature-gate unused code when necessary.
- Write tests for new functionality and resolve any reported problems.
- Pipeline secrets are stored in the `prod` environment.
- Interact with pipelines locally using the [WRKFLW](https://github.com/bahdotsh/wrkflw) utility to validate and run GitHub workflows.
- Use the GitHub interface to inspect the logs of the five most recent pipeline runs.
- Use the [`dtolnay/rust-toolchain`](https://github.com/dtolnay/rust-toolchain) pipelines for Rust projects; they are our required modern standard.
- Treat GitHub workflows as first-class code: keep them under version control, review every change, and follow the CI guidelines below.
- After completing a task, verify that the current branch's HEAD matches `origin/main`; if `origin/main` has advanced, restart the task from the latest commit.

## Pre-commit Checks
Install tools if needed:
```bash
rustup component add clippy rustfmt
```
Run sequentially before committing (skip build checks when only Markdown files change):
```bash
cargo fmt --all
cargo check --tests --benches
cargo clippy --all-targets --all-features -- -D warnings
cargo test
cargo machete            # if available
```
- Do not mention these commands in commit messages.
- Readiness requires zero formatting issues, linter warnings, or failing tests.

## Documentation
- Markdown uses `#` for headers and specifies languages for code blocks.
- Markdown filenames must be ALL_CAPS with underscores between words.
- Comments and documentation are always in English.

## GitHub Workflow Guidelines

- Author workflows inside `.github/workflows` using lowercase hyphen-case filenames that end with `.yml`.
- Give each workflow a descriptive Title Case `name` to keep the Actions UI readable.
- Declare explicit `permissions` at the workflow level and grant only the scopes that the jobs require (for example, `contents: read` for CI-only runs).
- Add a `concurrency` block that cancels superseded runs; include `${{ github.ref }}` in the group identifier for push and pull request triggers.
- Set `env.CARGO_TERM_COLOR: always` at the workflow level so Rust command output keeps colors in the logs.
- Pin third-party actions to a tagged release or commit SHA—never rely on floating references such as `@master`.
- Start jobs that need repository files with `actions/checkout@v4`.
- Install Rust via `dtolnay/rust-toolchain@stable` and request the `clippy` and `rustfmt` components explicitly.
- Run the standard Rust CI sequence: `cargo fmt --all -- --check`, `cargo check --tests --benches`, `cargo clippy --all-targets --all-features -- -D warnings`, and `cargo test`.
- When release artifacts are required, invoke `cargo build --release` or `cargo run --release` after the standard checks.
- Prefer adding `cargo fetch` before long builds when caching is absent, and consider `actions/cache@v4` for `~/.cargo` and `target` if runtime becomes a bottleneck.
- Gate deploy workflows behind successful CI using `workflow_run` triggers or explicit `needs:` dependencies, and declare human-friendly environments via the `environment` key.
- Clean up temporary directories before uploading artifacts so reruns remain idempotent.

## Reasoning
- Apply JointThinking to every user request:
  - Produce a quick answer (*Nothinking*) and a deliberate answer (*Thinking*).
  - If both answers match, return the *Thinking* version.
  - If they differ, analyze both and output a revised *Thinking* response.
- Formatting example:
  ```
  [Nothinking] fast answer
  [Thinking] detailed answer

  [Thinking:revision] refined answer
  ```

