# Avatar Repository Specification

## 1. Purpose

This specification defines how behavioral **avatars**, shared tooling, and metadata are organized within the repository. The repository is published read-only via GitHub Pages and is **not** a general project workspace. Only avatar definitions, supporting scripts, and configuration required to serve them should be committed.

## 2. Directory Layout

```
/avatars/
  DEVOPS.md
  QA.md
  ANALYST.md
  ...
README.md
SPECIFICATION.md
mcp.json
(optional) src/ or generator.rs
```

- `/avatars/` stores every avatar Markdown file.
- `Agents.md` contains shared base instructions bundled into the index.
- `src/` or `generator.rs` may host tooling that produces `avatars/index.json`.

## 3. Avatar File Format

Each avatar resides in `/avatars/` as a Markdown (`.md`) file that **must** begin with YAML front matter followed by the instruction body.

### 3.1 Front-matter schema

| Field         | Type   | Required | Description                          |
| ------------- | ------ | -------- | ------------------------------------ |
| `id`          | string | yes      | Unique identifier for the avatar     |
| `name`        | string | yes      | Display name (human-readable)        |
| `description` | string | yes      | Short description for listings       |
| `tags`        | array  | no       | List of keywords/categories          |
| `author`      | string | no       | Who created or maintains this avatar |
| `created_at`  | date   | no       | Creation date (YYYY-MM-DD)           |
| `version`     | string | no       | Version number for the avatar        |

Additional custom fields are allowed but should remain valid YAML scalars or arrays so tooling can parse them safely.

### 3.2 Example avatar

```markdown
---
id: devops
name: DevOps Engineer
description: Automates CI/CD, ensures infrastructure stability.
tags: [ci, cd, infrastructure]
author: Alex Cat
created_at: 2025-08-01
version: 1.0
---

# DevOps Engineer

You are a DevOps engineer. Your job is to:
- Automate CI/CD processes.
- Ensure infrastructure security and stability.
- Recommend best practices to the team.
```

### 3.3 Content guidelines

- Use Markdown headings to structure the instruction body.
- Keep actionable steps concise and written in English.
- Avoid repository-specific secrets or credentials.
- Document any required tools or workflows inside the avatar text.

## 4. Index Generation

Tooling may iterate over `/avatars/`, parse YAML front matter, and produce `avatars/index.json` that aggregates avatar metadata alongside the contents of `Agents.md`. The resulting JSON is published on GitHub Pages as both `avatars.json` and the legacy alias `avatars/index.json` and consumed by clients.

Example index entry produced from the front matter above:

```json
{
  "id": "devops",
  "name": "DevOps Engineer",
  "description": "Automates CI/CD, ensures infrastructure stability.",
  "tags": ["ci", "cd", "infrastructure"]
}
```

## 5. API and MCP Access

- **Catalog and base instructions:** `GET /avatars.json` (the legacy alias `GET /avatars/index.json` remains available).
- **Full avatar:** `GET /avatars/{id}.md`

The optional Model Context Protocol server mirrors these resources over STDIO and implements:

- `resources/list` – advertises the catalog (`avatars.json`, also available at `avatars/index.json`) along with shared base instructions.
- `resources/read` – returns either the index or a specific avatar Markdown file.

## 6. Extensibility and Tooling

- Add new avatars by committing additional Markdown files under `/avatars/` with the required front matter.
- Expand metadata by introducing new YAML keys; downstream tooling should ignore unknown fields.
- A Rust CLI (typically under `src/`) can regenerate `avatars/index.json` via `cargo run --release`; the GitHub Pages deployment publishes the result as both `avatars.json` and `avatars/index.json`.

## 7. Relationship to README

`README.md` provides a high-level overview and onboarding notes. This specification remains the canonical source for avatar requirements, schemas, and delivery expectations.
