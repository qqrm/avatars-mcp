# Universal Agent Instructions

## Strategy
- Review `AGENTS.md` files in the current scope before making changes.
- Consult repository documentation such as `ARCHITECTURE.md` or `SPECIFICATION.md` if available.
- Adapt these guidelines to the context of each project.

## Communication
- Replies to users should be short and in **Russian**.
- Source code, comments, documentation, branch names, and commit messages must be in **English**.
- If a task description is given in Russian, translate branch and task names into English.
- Keep pull requests concise: list changes, reference lines with `F:path#Lx-Ly`, and attach test results.

## Development Workflow
- Treat user requests as complete tasks and deliver full pull-request solutions.
- Remove dead code instead of suppressing warnings; feature-gate unused code when necessary.
- Write tests for new functionality and resolve any reported problems.
- Clone repositories from their official source, work on the `main` branch, and keep `origin` configured for rebasing.

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
