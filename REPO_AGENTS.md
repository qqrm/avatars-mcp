# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Critical Checklist
- Confirm `git remote -v` and `gh auth status` before making changes; Codex bootstrap scripts already configure the workspace.
- Leave the bootstrap `work` branch immediately, create a descriptive feature branch, and avoid any branch named `WORK`.
- Follow the global Source Control checklist: clean up stale remote branches with `gh`, close any linked pull requests, and reproduce the repository's required workflows locally with `wrkflw` before reporting completion.
- Treat the GitHub Pages deployment as the source of truth for `avatars.json`: it rebuilds the catalog automatically whenever `main` is published. Run `cargo run -p avatars-cli --release` only when you need a local preview or to debug generator failures, and avoid committing derived `avatars/catalog.json` output unless the task explicitly changes the generator.

## Environment Checks
- If `git remote -v` or `gh auth status` show problems, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Branch Management and Handoff
This repository follows the global branching guidance in `AGENTS.md`. Push every commit to the same feature branch, reproduce the required checks locally, and hand the branch to maintainers so they can open the pull request manually via Codex.
