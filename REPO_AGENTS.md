# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Critical Checklist
- Confirm `git remote -v` and `gh auth status` before making changes; Codex bootstrap scripts already configure the workspace.
- Leave the bootstrap `work` branch immediately, create a descriptive feature branch, and avoid any branch named `WORK`.
- Follow the global Source Control checklist and reproduce the repository's required workflows locally with `wrkflw` before reporting completion.
- Treat the GitHub Pages deployment as the source of truth for `avatars.json`: it rebuilds the catalog automatically whenever `main` is published. Run `cargo run -p avatars-cli --release` (or rely on the workspace default with `cargo run --release`) only when you need a local preview or to debug generator failures, and avoid committing derived `avatars/catalog.json` output unless the task explicitly changes the generator.

## Environment Checks
- If `git remote -v` or `gh auth status` show problems, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Branch Management and Handoff
