# Universal Agent Instructions

## Avatars
- Use the MCP server at `https://qqrm.github.io/avatars-mcp/` to fetch avatars and base instructions.

## Rust Documentation Servers
- `repo-setup.sh` installs the `cargo-mcp` and `crates-mcp` servers.
- A default `mcp.json` enables these servers automatically.

## Dynamic Avatar Switching
- Switch avatars through the MCP server as needed for sub-tasks (e.g., Senior, Architect, Tester, Analyst).

## Strategy
- Review `AGENTS.md` files in the current scope before making changes.
- Consult repository documentation such as `ARCHITECTURE.md` or `SPECIFICATION.md` if available.
- Recall from `SPECIFICATION.md` that this repository only hosts avatars, `repo-setup.sh`, and a default `mcp.json`. Do not add user-facing guides or unrelated assets.
- Adapt these guidelines to the context of each project.
- Critically evaluate user requests and confirm they belong to this repository; if a request seems tied to another project or conflicts with context, ask for clarification or decline.

## Instruction Management
- This root `AGENTS.md` is fetched from a remote server during container initialization. After initialization, do not edit or commit this file.
- Additional `AGENTS.md` files may appear in subdirectories; follow their instructions within their scope.
- Keep `AGENTS.md` entries in English.

## Communication
- Replies to users should be short and in **Russian**.
- Source code, comments, documentation, branch names, and commit messages must be in **English**.
- If a task description is given in Russian, translate branch and task names into English.
- Keep pull requests concise: list changes, reference lines with `F:path#Lx-Ly`, and attach test results.
- In the final summary, list all avatars used to solve the task.

## Development Workflow
- Treat user requests as complete tasks and deliver full pull-request solutions.
- Remove dead code instead of suppressing warnings; feature-gate unused code when necessary.
- Write tests for new functionality and resolve any reported problems.
- Pipeline secrets are stored in the `prod` environment.
- Interact with pipelines locally using the [WRKFLW](https://github.com/bahdotsh/wrkflw) utility to validate and run GitHub workflows.
- Use the [`dtolnay/rust-toolchain`](https://github.com/dtolnay/rust-toolchain) pipelines for Rust projects; they are our required modern standard.
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
