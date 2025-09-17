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

Run `./setup.sh` (or `repo-setup.sh` when present) to install the optional MCP servers referenced by `mcp.json`.

## Documentation

- **Specification:** See [`SPECIFICATION.md`](SPECIFICATION.md) for the canonical directory layout, avatar schema, and API details.
- **Avatars:** Individual prompts live in [`/avatars/`](avatars/); each file targets a single role.
- **Base instructions:** Shared guidance for all avatars resides in [`BASE_AGENTS.md`](BASE_AGENTS.md).

## Tooling

A Rust CLI located in [`src/`](src) regenerates `avatars/index.json` by parsing the avatar front matter and bundling `BASE_AGENTS.md`. Build the index with:

```bash
cargo run --release
```
### GitHub Pages Publishing

The [GitHub Pages workflow](.github/workflows/pages.yml) rebuilds `avatars/index.json` and publishes the `avatars/` directory to GitHub Pages whenever updates land on `main` or release tags. Refer to the workflow file for the complete automation steps.

### Published API

The latest version of the avatar API is served from GitHub Pages at:

```text
https://qqrm.github.io/avatars-mcp/
```

You can browse individual avatar files or fetch `avatars/index.json` from that URL, for example:

```text
https://qqrm.github.io/avatars-mcp/avatars/index.json
```

Continuous integration pipelines lint and test the Rust tooling (`cargo fmt`, `cargo clippy`, and `cargo test`). GitHub Pages deployments rebuild `avatars/index.json` from `main` and publish both the index and avatar Markdown files under `https://qqrm.github.io/avatars-mcp/`.

For detailed schemas, examples, and API usage, always defer to `SPECIFICATION.md`.
