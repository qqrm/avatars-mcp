# Avatar Repository

This repository stores behavioral **avatars** for AI agents. Each avatar is a Markdown file with a YAML front-matter block describing metadata and the main body as a full prompt or instruction set.

## Specification

```
/avatars/
  devops.md
  qa.md
  analyst.md
  ...
README.md
(specification.md)
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

An optional Model Context Protocol (MCP) server exposes the same avatar data over
STDIO.

Run it with:

```
cargo run --bin server
```

The server implements the following methods:

- `resources/list` – list all available avatars.
- `resources/read` – read the Markdown for a specific avatar.

Example configuration for an MCP client:

```json
{
  "mcpServers": [
    {
      "name": "avatars",
      "command": "cargo",
      "args": ["run", "--bin", "server"]
    }
  ]
}
```

### Generator (Rust)

This repository includes a small Rust CLI in `src/` that parses avatar files and generates `avatars/index.json`. Run `cargo run --release` to build the index.

### GitHub Pages Deployment

A workflow in `.github/workflows/pages.yml` rebuilds `avatars/index.json` and publishes the `avatars/` directory as a GitHub Pages site. It runs on pushes to `main` or release tags, installs the stable Rust toolchain, runs `cargo run --release`, then uploads the directory for deployment.
---

### GitHub Pages Workflow

- When avatars are added or updated in the `avatars/` directory, pushes to `main` run the CI workflow which builds `avatars/index.json`.
- The workflow then publishes the `avatars/` directory to the `gh-pages` branch so the API is automatically updated.

### Published API

The latest version of the avatar API is served from GitHub Pages at:

```
https://<github-user>.github.io/avatars-mcp/
```

You can browse individual avatar files or fetch `avatars/index.json` from that URL.

### Release Versioning

Releases are tagged using semantic versioning: `v<major>.<minor>.<patch>`. Tags correspond to stable snapshots of the avatar collection.
