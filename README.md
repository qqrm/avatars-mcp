# Codex Tools

This repository hosts behavioral **avatars** for Codex agents. Avatars are Markdown prompts with YAML front matter that describe specialized roles. The collection is published read-only through GitHub Pages for direct consumption by automation and other integrations.

## Avatar Usage Guidelines

- Always select an avatar before starting work on a task so the agent operates from a clear perspective.
- Switch avatars explicitly when the task changes focus and document the active persona in status updates.
- Align tooling and communication with the currently selected avatar to keep expectations consistent for collaborators.

## Remote Setup

Configure the Git remote if it is missing:

```bash
git remote add origin https://github.com/qqrm/codex-tools.git
git fetch origin
```

### Container bootstrap commands

Three published entry points cover the common Codex container workflows. Each snippet downloads the script from the GitHub Pages deployment and executes it directly:

> **Note:** The scripts refresh shared instructions from GitHub Pages before running. Override the download origin by exporting `PAGES_BASE_URL` when testing mirrors or forks.

> **Bundle layout:** The published artifact exposes only the three entry-point scripts under `/scripts/`. Each helper is self-contained and interacts with repository-local tooling when available.

#### Non-cached container — full initialization
- Downloads the latest `AGENTS.md` from GitHub Pages to prime the workspace
- Performs the same tooling setup as the cached workflow on a brand new container
- Stores GitHub authentication, validates repository access, and installs the cleanup workflow

```bash
curl -fsSL "https://qqrm.github.io/codex-tools/scripts/FullInitialization.sh" | bash -s --
```

#### Cached container — full initialization
- Installs GitHub CLI, Rust, cargo-binstall, and helper tooling
- Persists GitHub authentication for later reuse inside the cached image
- Verifies repository access and installs the Codex cleanup workflow once

```bash
curl -fsSL "https://qqrm.github.io/codex-tools/scripts/BaseInitialization.sh" | bash -s --
```

#### Cached container — lightweight refresh before a task
- Updates the workspace copy of `AGENTS.md` from GitHub Pages

```bash
curl -fsSL "https://qqrm.github.io/codex-tools/scripts/PretaskInitialization.sh" | bash -s --
```

## Documentation

- **Specification:** See [`SPECIFICATION.md`](docs/SPECIFICATION.md) for the canonical directory layout, avatar schema, and delivery expectations.
- **Avatars:** Individual prompts live in [`/avatars/`](avatars/); each file targets a single role.
- **Base instructions:** Shared guidance for all avatars resides in [`AGENTS.md`](AGENTS.md).
- **HTTP quick reference:** [`INSTRUCTIONS.md`](docs/INSTRUCTIONS.md) summarizes the published endpoints external clients call.

## Shared Files for External Consumers

External clients rely on a small set of shared files published alongside the avatars:

- [`AGENTS.md`](AGENTS.md) — the baseline instructions served to external agents, embedded in and linked from the published `avatars.json` catalog.
- [`INSTRUCTIONS.md`](docs/INSTRUCTIONS.md) — a condensed description of the HTTP API exposed via GitHub Pages.

Repository tooling keeps these artifacts in sync for local use:

- [`scripts/BaseInitialization.sh`](scripts/BaseInitialization.sh) — installs the required tooling and persists GitHub CLI authentication for cached containers.
- [`scripts/FullInitialization.sh`](scripts/FullInitialization.sh) — performs the full bootstrap on a fresh, non-cached container.
- [`scripts/PretaskInitialization.sh`](scripts/PretaskInitialization.sh) — refreshes the published assets before each task.

Only these entry points are published on GitHub Pages.

## Bootstrap Script Architecture

Codex repositories rely on a consistent bootstrap bundle to provision development containers. This repository publishes the entire bundle to GitHub Pages so automation can curl a single entry point and receive every dependency from the same source.

- **Entry points:** `scripts/BaseInitialization.sh`, `scripts/FullInitialization.sh`, and `scripts/PretaskInitialization.sh` are the only public URLs automation should call. Each script executes its workflow directly without sourcing additional helpers.
- **Mirroring strategy:** The scripts default to `https://qqrm.github.io/codex-tools` for every remote fetch, keeping the GitHub repository out of the execution path unless you override the base URL explicitly.

The published bundle initializes Codex-compatible containers by installing shared tooling, syncing repository assets, and verifying workflow prerequisites. Downstream repositories copy this pattern to keep container setup reproducible.

## Tooling

A Rust workspace under [`/crates/`](crates/) regenerates the catalog stored at [`avatars/catalog.json`](avatars/catalog.json) by parsing the avatar front matter and bundling both the base instructions and avatar metadata. The GitHub Pages deployment exposes this catalog as `avatars.json` (the legacy `/catalog.json` alias is intentionally unavailable; clients must request `/avatars.json`). The deployment pipeline rebuilds the index automatically whenever `main` changes, so running the generator locally is only necessary for debugging or previewing changes. Build the index with:

```bash
cargo run --release
```

Clients begin with `avatars.json` to decide which personas they need, then fetch `AGENTS.md` and the target avatars on demand to avoid loading unnecessary Markdown into the working context. Requests to `/catalog.json` return `404 Not Found` by design; update clients rather than adding an alias.

### GitHub Pages Publishing

The [GitHub Pages workflow](.github/workflows/pages.yml) publishes the avatar catalog, shared instructions, and Markdown prompts whenever updates land on `main`. Refer to the workflow file for the complete automation steps.

### Published API

The latest version of the avatar site is served from GitHub Pages at:

```text
https://qqrm.github.io/codex-tools/
```

- `GET /avatars.json` — retrieve the catalog, including the `base_uri` pointer to the shared instructions. The deployment does **not** publish `/catalog.json`.
- `GET /AGENTS.md` — download the shared baseline instructions referenced by `base_uri`.
- `GET /avatars/{id}.md` — retrieve the complete descriptor for the avatar with the given `id`.

Clients should fetch both the catalog and `AGENTS.md` to ensure they stay in sync with the published baseline guidance, because the catalog intentionally omits the Markdown body in favour of the shared URI.

Continuous integration pipelines lint and test the Rust tooling (`cargo fmt`, `cargo clippy`, and `cargo test`). GitHub Pages deployments rebuild the catalog from `main` and publish it to `https://qqrm.github.io/codex-tools/avatars.json` alongside the avatar Markdown files.

For detailed schemas, examples, and API usage, always defer to `SPECIFICATION.md`.
