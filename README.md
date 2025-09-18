# Avatar Repository

This repository hosts behavioral **avatars** for AI agents. Avatars are Markdown prompts with YAML metadata that describe specialized roles. The collection is published read-only through GitHub Pages for integration with Model Context Protocol (MCP) clients and other automation.

## Avatar Usage Guidelines

- Always select an avatar before starting work on a task so the agent operates from a clear perspective.
- Switch avatars explicitly when the task changes focus and document the active persona in status updates.
- Align tooling and communication with the currently selected avatar to keep expectations consistent for collaborators.

## Remote Setup

Configure the Git remote if it is missing:

```bash
git remote add origin https://github.com/qqrm/avatars-mcp.git
git fetch origin
```

Run `./setup.sh` to install the optional MCP servers referenced by `mcp.json`; it automatically invokes a repository-specific `repo-setup.sh` when present.

## Documentation

- **Specification:** See [`SPECIFICATION.md`](SPECIFICATION.md) for the canonical directory layout, avatar schema, and API details.
- **Avatars:** Individual prompts live in [`/avatars/`](avatars/); each file targets a single role.
- **Base instructions:** Shared guidance for all avatars resides in [`AGENTS.md`](AGENTS.md).
- **HTTP quick reference:** [`INSTRUCTIONS.md`](INSTRUCTIONS.md) summarizes the published endpoints external clients call.

## Shared Files for External Consumers

External clients rely on a small set of shared files published alongside the avatars:

- [`AGENTS.md`](AGENTS.md) — the baseline instructions served to external agents and bundled into the published `avatars.json` catalog.
- [`INSTRUCTIONS.md`](INSTRUCTIONS.md) — a condensed description of the HTTP API exposed via GitHub Pages.
- [`mcp.json`](mcp.json) — the default Model Context Protocol manifest that activates these resources in compatible clients.

Repository tooling keeps these artifacts in sync for local use:

- [`setup.sh`](setup.sh) — a POSIX shell bootstrapper that installs tooling while mirroring the published baseline instructions and avatar index.

## Repository-Specific Setup Script

Every repository in this ecosystem can ship its own local setup helper tailored to its automation requirements under the shared
name `repo-setup.sh`. The [`setup.sh`](setup.sh) script in this repository provisions GitHub CLI authentication,
installs required Rust tooling, refreshes the published MCP assets directly, and then runs `repo-setup.sh`
if it exists. When working in other repositories, expect their `repo-setup.sh` contents to diverge—each project documents and
automates only the dependencies it needs while keeping the filename consistent.

## Tooling

A Rust CLI located in [`src/`](src) regenerates the catalog stored at [`avatars/catalog.json`](avatars/catalog.json) by parsing the avatar front matter and bundling `AGENTS.md`. The GitHub Pages deployment exposes this catalog as `avatars.json`. Build the index with:

```bash
cargo run --release
```
### GitHub Pages Publishing

The [GitHub Pages workflow](.github/workflows/pages.yml) rebuilds the avatar catalog, publishes it as `avatars.json` (with a duplicate `index.json` for convenience), and syncs the `avatars/` directory whenever updates land on `main` or release tags. Refer to the workflow file for the complete automation steps.

### Published API

The latest version of the avatar API is served from GitHub Pages at:

```text
https://qqrm.github.io/avatars-mcp/
```

You can browse individual avatar files or fetch the catalog directly from `avatars.json`, for example:

```text
https://qqrm.github.io/avatars-mcp/avatars.json
```

Continuous integration pipelines lint and test the Rust tooling (`cargo fmt`, `cargo clippy`, and `cargo test`). GitHub Pages deployments rebuild the catalog from `main` and publish it to `https://qqrm.github.io/avatars-mcp/avatars.json` alongside the avatar Markdown files.

For detailed schemas, examples, and API usage, always defer to `SPECIFICATION.md`.
