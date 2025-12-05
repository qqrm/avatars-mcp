# Zizmor Audit: codex-tools (GitHub Actions)

- **Command:** `zizmor --format json --collect workflows --collect dependabot --collect actions --no-progress -- .` (v1.18.0).
- **Summary:** 7 findings across the CI and Pages workflows; none in Dependabot config or reusable actions.

## Findings by workflow

### .github/workflows/ci.yml
- `artipacked` (Medium): `actions/checkout@v4` does not set `persist-credentials: false` in the CI job, leaving persisted tokens on the runner. 【F:.github/workflows/ci.yml†L20-L33】
- `unpinned-uses` (High): `dtolnay/rust-toolchain@stable` is referenced without a commit SHA. 【F:.github/workflows/ci.yml†L29-L33】

### .github/workflows/pages.yml
- `dangerous-triggers` (High): the workflow uses `workflow_run`, which Zizmor treats as insecure by default. 【F:.github/workflows/pages.yml†L3-L7】
- `excessive-permissions` (High, 2 findings): workflow-level `pages: write` and `id-token: write` grants exceed least-privilege defaults. 【F:.github/workflows/pages.yml†L8-L11】
- `artipacked` (Medium): `actions/checkout@v4` does not disable credential persistence in the Pages build job. 【F:.github/workflows/pages.yml†L27-L33】
- `unpinned-uses` (High): the Pages workflow pins `dtolnay/rust-toolchain` only to `stable` rather than a specific commit. 【F:.github/workflows/pages.yml†L33-L37】
