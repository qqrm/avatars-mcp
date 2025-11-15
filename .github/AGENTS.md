# Agent Instructions – GitHub Configuration

These rules apply to everything under `.github`.

## Workflow Authoring
- Place GitHub workflow definitions inside `.github/workflows` using lowercase hyphen-case filenames that end with `.yml`.
- Give each workflow a descriptive Title Case `name` so runs are easy to identify.
- Use the exact workflow title `Codex Branch Cleanup` for the scheduled Codex branch pruning pipeline so cross-repository automation can recognise it consistently.
- Keep triggers minimal: default to `push`/`pull_request` on `main` and add extra events only when the feature requires them.
- Name jobs in lowercase with hyphenated identifiers (for example, `build`, `deploy`) and prefer a single responsibility per job.

## Consistency Requirements
- Declare explicit `permissions` for every workflow, using the least privilege needed (e.g., `contents: read` for CI-only jobs).
- Add a `concurrency` block to cancel superseded runs; use workflow-specific groups that include `${{ github.ref }}` for push/PR triggers.
- Set `env.CARGO_TERM_COLOR: always` at the workflow level to keep Rust command output readable in the logs.
- Pin third-party actions to a tagged major release or commit SHA; avoid floating references like `@master`.
- Use `actions/checkout@v4` as the first step of each job that needs repository files.

## Rust Toolchain and Checks
- Install Rust with `dtolnay/rust-toolchain@stable` and always request the `clippy` and `rustfmt` components.
- Run the standard command sequence for Rust CI jobs: `cargo fmt --all -- --check`, `cargo check --tests --benches`, `cargo clippy --all-targets --all-features -- -D warnings`, and `cargo test`.
- When a workflow needs release artifacts, call `cargo build --release` or `cargo run --release` explicitly after the standard checks.
- Prefer `cargo fetch` before lengthy builds when caching is not configured, and add a shared `actions/cache@v4` setup for `~/.cargo` and `target` if runtime becomes a concern.

## Deployment Pipelines
- Gate deploy workflows behind successful CI runs using `workflow_run` triggers or explicit `needs:` dependencies.
- Keep deployment environments declared via the `environment` key and provide human-friendly names (e.g., `github-pages`).
- Ensure artifact packaging steps are idempotent and clean up any temporary directories inside the workspace before uploading.

## Validation
- Document any deliberate deviations from these rules inside the affected workflow file so reviewers understand the exception.
