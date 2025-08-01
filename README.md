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

### Generator (Rust)

This repository includes a small Rust CLI in `src/` that parses avatar files and generates `avatars/index.json`. Run `cargo run --release` to build the index.
---
