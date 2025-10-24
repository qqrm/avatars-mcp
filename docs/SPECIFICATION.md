# Codex Tools Specification

## 1. Purpose

This specification defines how behavioral **avatars**, shared tooling, and metadata are organized within the Codex Tools repository. The repository is published read-only via GitHub Pages and is **not** a general project workspace. Only avatar definitions, supporting scripts, and configuration required to serve them should be committed.

## 2. Directory Layout

```
/avatars/
  DEVOPS.md
  QA.md
  ANALYST.md
  ...
README.md
SPECIFICATION.md
(optional) crates/
(optional) scripts/
```

- `/avatars/` stores every avatar Markdown file.
- `AGENTS.md` contains shared base instructions bundled into the index.
- `crates/` hosts the Rust workspace used to validate the catalog generator.
- `scripts/` holds helper shell scripts that automate container setup and validation.

## 3. Avatar File Format

Each avatar resides in `/avatars/` as a Markdown (`.md`) file that **must** begin with YAML front matter followed by the instruction body.

### 3.1 Front-matter schema

| Field         | Type   | Required | Description                          |
| ------------- | ------ | -------- | ------------------------------------ |
| `id`          | string | yes      | Unique identifier for the avatar     |
| `name`        | string | yes      | Display name (human-readable)        |
| `description` | string | no       | Short description for listings       |
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

## 4. Catalog Generation

Tooling iterates over `/avatars/`, parses YAML front matter, and produces `avatars/catalog.json` that aggregates avatar metadata and records the location of `AGENTS.md`. The resulting JSON is published on GitHub Pages as `avatars.json`. The checked-in `avatars/catalog.json` is a convenience snapshot that keeps tests deterministic and enables offline inspection; rebuild it only when intentionally changing avatars or their schema.

### 4.1 Catalog schema

The catalog schema is:

```json
{
  "base_uri": "AGENTS.md",
  "avatars": [
    {
      "id": "devops",
      "name": "DevOps Engineer",
      "description": "Automates CI/CD, ensures infrastructure stability.",
      "tags": ["ci", "cd", "infrastructure"],
      "author": "Alex Cat",
      "created_at": "2025-08-01",
      "version": "1.0",
      "uri": "avatars/DEVOPS.md"
    }
  ]
}
```

- `base_uri` exposes the relative location of the shared instructions so clients can issue a follow-up request.
- `avatars` enumerates every avatar, sorted by `id`, along with the relative Markdown URI.

### 4.2 Delivery model

Clients begin by fetching `avatars.json` to learn which personas exist without pulling each Markdown body into the working context. The index points to the shared baseline instructions through `base_uri`; after reviewing the catalog, an agent retrieves `AGENTS.md` and then issues targeted requests for only the avatars it needs. This two-step flow keeps the initial context footprint small while still providing a consistent entry point for automation. Requests to `/catalog.json` should be treated as configuration errors.

## 5. API Endpoints

GitHub Pages exposes the repository at `https://qqrm.github.io/codex-tools/`. Clients rely on the following endpoints:

- **Catalog and base instructions:** `GET /avatars.json`.
- **Incorrect legacy path:** `GET /catalog.json` returns `404 Not Found` and indicates a misconfigured client.
- **Baseline instructions only:** `GET /AGENTS.md`.
- **Full avatar:** `GET /avatars/{id}.md`.

## 6. Extensibility and Tooling

- Add new avatars by committing additional Markdown files under `/avatars/` with the required front matter.
- Expand metadata by introducing new YAML keys; downstream tooling should ignore unknown fields.
- The Rust workspace under `crates/` regenerates `avatars/catalog.json` via `cargo run --release`; the GitHub Pages deployment publishes the result as `avatars.json`.

## 7. Relationship to README

`README.md` provides a high-level overview and onboarding notes. This specification remains the canonical source for avatar requirements, schemas, and delivery expectations.

## 8. Bootstrap Bundle Expectations

Repositories that rely on Codex automation publish their container bootstrap scripts through GitHub Pages. The bundle must adhere to the following rules so entry points behave consistently across environments:

- **Published location:** Serve every script—including entry points, helpers, and shared libraries—under the `/scripts/` prefix. Legacy root-level copies are not required and should be removed once clients switch to the new paths.
- **Entry points:** Ship the three wrappers (`split-initialization-cached-base.sh`, `full-initialization.sh`, and `split-initialization-pretask.sh`) as the only public interfaces. They download helper scripts such as `bootstrap-*.sh` and `repo-setup.sh` into a temporary directory before execution.
- **Shared helpers:** Include `scripts/lib/container-bootstrap-common.sh` in the published bundle so wrappers can source shared functions without additional requests.
- **Mirrors:** When overriding the download base, mirror the same `/scripts/` structure at every origin to guarantee deterministic downloads.

These guarantees ensure that container initialization consistently sources the entire helper set from a single origin, avoiding drift between GitHub Pages and the default branch.
