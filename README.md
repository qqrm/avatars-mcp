# Avatar Repository

This repository stores behavioral **avatars** for AI agents. Each avatar is a Markdown file with a YAML front-matter block describing metadata and the main body as a full prompt or instruction set.

## Remote Setup

Configure the `origin` remote if it is missing:

```bash
git remote add origin https://github.com/qqrm/avatars-mcp.git
git fetch origin
```

## Specification

```
/avatars/
  DEVOPS.md
  QA.md
  ANALYST.md
  ...
README.md
(SPECIFICATION.md)
(optional: generator.rs)
```

Each avatar is a `.md` file in `/avatars/`, beginning with a YAML front-matter block:

```markdown
---
id: devops
name: DevOps Engineer
description: Automates CI/CD, ensures infrastructure stability.
tags: [ci, cd, infrastructure]
author: QQRM
created_at: 2025-08-02
version: 0.1
---

# DevOps Engineer

You are a DevOps engineer. Your job is to:
- Automate CI/CD processes.
- Ensure infrastructure security and stability.
- Recommend best practices to the team.
```

### Required front-matter fields

| Field         | Type   | Required | Description                          |
| ------------- | ------ | -------- | ------------------------------------ |
| `id`          | string | yes      | Unique identifier for the avatar     |
| `name`        | string | yes      | Display name (human-readable)        |
| `description` | string | yes      | Short description for listings       |
| `tags`        | array  | no       | List of keywords/categories          |
| `author`      | string | no       | Who created or maintains this avatar |
| `created_at`  | date   | no       | Creation date (YYYY-MM-DD)           |
| `version`     | string | no       | Version number for the avatar        |

The main content begins after the front-matter block.

### Listing Generation

An index can be built by parsing the front matter of all `.md` files in `/avatars/`.

### API Access

- **List all avatars:** GET `/avatars/`
- **Get full avatar:** GET `/avatars/{id}.md`
- **Get generated index:** GET `/avatars/index.json` (optional)

### MCP Server

An optional Model Context Protocol (MCP) server exposes the avatar data and base
`AGENTS.md` instructions over STDIO.

Run it with:

```
cargo run --bin mcp_server
```

The server implements the following methods:

- `resources/list` – list all available avatars and the base instructions.
- `resources/read` – read the Markdown for a specific avatar or `AGENTS.md`.

Example configuration for an MCP client:

```json
{
  "mcpServers": [
    {
      "name": "avatars",
      "command": "cargo",
      "args": ["run", "--bin", "mcp_server"]
    }
  ]
}
```

### Generator (Rust)

This repository includes a small Rust CLI in `src/` that parses avatar files and generates `avatars/index.json`. Run `cargo run --release` to build the index.

### CI Workflow

The workflow in `.github/workflows/ci.yml` ensures that code is formatted, linted, and tested:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -D warnings
cargo test
```

### GitHub Pages Deployment

 A workflow in `.github/workflows/pages.yml` rebuilds `avatars/index.json` and publishes it under the `avatars/` path on GitHub Pages. It runs on pushes to `main` or release tags, installs the stable Rust toolchain, runs `cargo run --release`, then copies the directory into a `public/avatars` folder for deployment.
---

### GitHub Pages Workflow

- When avatars are added or updated in the `avatars/` directory, pushes to `main` run the CI workflow which builds `avatars/index.json`.
- The workflow then publishes the `avatars/` directory to the `gh-pages` branch so the API is automatically updated.

### Published API

The latest version of the avatar API is served from GitHub Pages at:

```
https://qqrm.github.io/avatars-mcp/
```

You can browse individual avatar files or fetch `avatars/index.json` from that URL, for example:

```
https://qqrm.github.io/avatars-mcp/avatars/index.json
```

### Release Versioning

Releases are tagged using semantic versioning: `v<major>.<minor>.<patch>`. Tags correspond to stable snapshots of the avatar collection.
