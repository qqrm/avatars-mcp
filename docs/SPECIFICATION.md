# Codex Tools Specification

## 1. Purpose

This specification defines how behavioral **personas**, shared tooling, and metadata are organized within the Codex Tools repository. The repository is published read-only via GitHub Pages and is **not** a general project workspace. Only persona definitions, supporting scripts, and configuration required to serve them should be committed.

## 2. Directory Layout

Codex Tools repositories expose a small, predictable set of files so that automation can discover personas, shared instructions,
and supporting documentation without scanning unrelated content.

### 2.1 Required structure

```
/
  AGENTS.md
  docs/
    INSTRUCTIONS.md
    SPECIFICATION.md
  personas/
```

- `AGENTS.md` lives at the repository root and defines the shared baseline instructions referenced by the catalog `base_uri`.
- `docs/` contains public documentation. At minimum it must include this specification and `INSTRUCTIONS.md`, which summarizes
  the published HTTP endpoints.
- `/personas/` stores every persona Markdown file described in Section 3.

### 2.2 Optional directories

Repositories may include additional helpers when needed:

```
(optional) crates/
(optional) scripts/
```

- `crates/` hosts the Rust workspace used to validate the persona catalog generator.
- `scripts/` holds helper shell scripts that automate container setup and validation when repositories choose to publish a
  bootstrap bundle.

## 3. Persona File Format

Each persona resides in `/personas/` as a Markdown (`.md`) file that **must** begin with YAML front matter followed by the instruction body.

### 3.1 Front-matter schema

| Field         | Type   | Required | Description                          |
| ------------- | ------ | -------- | ------------------------------------ |
| `id`          | string | yes      | Unique identifier for the persona     |
| `name`        | string | yes      | Display name (human-readable)        |
| `description` | string | no       | Short description for listings       |
| `tags`        | array  | no       | List of keywords/categories          |
| `author`      | string | no       | Who created or maintains this persona |
| `created_at`  | date   | no       | Creation date (YYYY-MM-DD)           |
| `version`     | string | no       | Version number for the persona        |

Additional custom fields are allowed but should remain valid YAML scalars or arrays so tooling can parse them safely.

### 3.2 Example persona

```markdown
---
id: delivery_engineer
name: Delivery Engineer
description: Ships production-grade Rust changes with measurable outcomes.
tags: [rust, implementation, quality]
author: QQRM
created_at: 2025-08-13
version: 0.2
---

# Delivery Engineer

## Role Snapshot
Hands-on implementer converting approved designs into reliable code.

## Responsibilities Checklist
- Break features into incremental commits with tests and documentation.
- Maintain clean dependencies and enforce agreed coding standards.

## When to Switch Away
- Architectural decisions remain open → involve the Solution Architect.

## Required Artifacts
- Implementation plan, PR checklist, and post-merge monitoring notes.

## Collaboration Signals
- Share upcoming changes with Quality and Reliability & Security engineers.
```

### 3.3 Content guidelines

- Use Markdown headings to structure the instruction body.
- Keep actionable steps concise and written in English.
- Avoid repository-specific secrets or credentials.
- Document any required tools or workflows inside the persona text.

### 3.4 Minimum instruction blocks

Every persona must include the following Markdown structure after the YAML front matter:

- `# <Role Name>` level-one heading matching the `name` field.
- `## Role Snapshot` summarizing the persona's scope and perspective.
- `## Responsibilities Checklist` detailing the non-negotiable duties for the persona.
- `## When to Switch Away` clarifying triggers for handing the task to another persona.
- `## Required Artifacts` listing the tangible outputs that must accompany each handoff.
- `## Collaboration Signals` describing coordination expectations with adjacent roles.

Optional extensions—such as collaboration guidelines, anti-patterns, or playbooks—are encouraged when they improve clarity, but they must appear under clearly labeled headings so automation can parse the required baseline consistently.

## 4. Catalog Generation

Tooling iterates over `/personas/`, parses YAML front matter, and produces `personas/catalog.json` that aggregates persona metadata and records the location of `AGENTS.md`. The resulting JSON is published on GitHub Pages as `personas.json`. The checked-in `personas/catalog.json` is a convenience snapshot that keeps tests deterministic and enables offline inspection; rebuild it only when intentionally changing personas or their schema.

### 4.1 Catalog schema

The catalog schema is:

```json
{
  "base_uri": "AGENTS.md",
  "personas": [
    {
      "id": "reliability_security",
      "name": "Reliability & Security Engineer",
      "description": "Protects availability, compliance, and secure delivery pipelines.",
      "tags": ["operations", "security", "resilience"],
      "author": "QQRM",
      "created_at": "2025-08-13",
      "version": "0.1",
      "uri": "https://qqrm.github.io/codex-tools/personas/RELIABILITY.md"
    }
  ]
}
```

- `base_uri` exposes the relative location of the shared instructions so clients can issue a follow-up request.
- `personas` enumerates every persona, sorted by `id`, along with the absolute Markdown URI hosted on GitHub Pages.

### 4.2 Delivery model

Clients begin by fetching `personas.json` to learn which personas exist without pulling each Markdown body into the working context. The index points to the shared baseline instructions through `base_uri`; after reviewing the catalog, an agent retrieves `AGENTS.md` and then issues targeted requests for only the personas it needs. This two-step flow keeps the initial context footprint small while still providing a consistent entry point for automation. Requests to `/catalog.json` should be treated as configuration errors.

## 5. API Endpoints

GitHub Pages exposes the repository at `https://qqrm.github.io/codex-tools/`. Clients rely on the following endpoints:

- **Catalog and base instructions:** `GET /personas.json`.
- **Incorrect legacy path:** `GET /catalog.json` returns `404 Not Found` and indicates a misconfigured client.
- **Baseline instructions only:** `GET /AGENTS.md`.
- **Full persona:** `GET /personas/{id}.md`.

## 6. Extensibility and Tooling

- Add new personas by committing additional Markdown files under `/personas/` with the required front matter.
- Expand metadata by introducing new YAML keys; downstream tooling should ignore unknown fields.
- The Rust workspace under `crates/` regenerates `personas/catalog.json` via `cargo run --release`; the GitHub Pages deployment publishes the result as `personas.json`.

## 7. Relationship to README

`README.md` provides a high-level overview and onboarding notes, including the detailed bootstrap expectations referenced in Section 8. This specification remains the canonical source for persona requirements, schemas, and delivery expectations.

## 8. Bootstrap Bundle Reference

The persona specification tracks only the minimum guarantees required for the catalog and documentation. Repositories that ship
bootstrap tooling must continue to publish it under `/scripts/` as noted in Section 2.2. Detailed bootstrap behavior, script
descriptions, and mirroring guidance are documented in `README.md` under “Bootstrap Script Architecture,” which now serves as the
authoritative reference for those workflows.
