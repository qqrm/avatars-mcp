# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Critical Checklist
- Confirm `git remote -v` and `gh auth status` before making changes; Codex bootstrap scripts already configure the workspace.
- Leave the bootstrap `work` branch immediately, create a descriptive feature branch, and avoid any branch named `WORK`.
- Treat the GitHub Pages deployment as the source of truth for `avatars.json`: it rebuilds the catalog automatically whenever `main` is published. Run `cargo run --release` only when you need a local preview or to debug generator failures, and avoid committing derived `avatars/catalog.json` output unless the task explicitly changes the generator.
- Enforce the Rust 2024 edition across the workspace: confirm that every crate manifest and shared toolchain configuration specifies `edition = "2024"` and correct any mismatch as part of the task.

## Preferred Rust Crates
Refer to [`docs/CRATE_GUIDE.md`](docs/CRATE_GUIDE.md) for the complete, regularly maintained catalog of recommended crates and usage notes. Review it before adding new dependencies and document any intentional deviations in code review.

## Environment Checks
- If `git remote -v` or `gh auth status` show problems, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Testing and Validation
- Run the full Rust validation suite from `AGENTS.md` whenever you modify Rust code or GitHub workflow files. In addition, this repository requires the docs build and Markdown validation scripts:
  ```bash
  ./scripts/build-pages.sh
  ./scripts/validate-pages.sh
  ```
- Documentation-only updates (Markdown, guides, `AGENTS.md` updates, etc.) may skip the heavier Rust commands when no Rust code changes, but you must still run the shell scripts above (and `cargo fmt --all` when applicable) and record any skipped tooling in your report.

## Branch Management and Handoff
