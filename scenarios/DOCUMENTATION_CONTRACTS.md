---
id: documentation_contracts
name: Documentation and Contracts Review
description: Verify public-facing docs, API contracts, and examples.
tags: [documentation, contracts, quality]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Documentation and Contracts Review

## Goal
Ensure public APIs and behaviors are documented, versioned, and backed by examples and invariants.

## When to Use
- Users request clearer docs or find mismatches with behavior.
- New APIs or breaking changes are being introduced.
- On-call/support teams see repeated questions.

## Inputs
- Public API surfaces and versioning policy.
- Existing docs (README, mdBook, rustdoc) and changelogs.
- Examples, error models, and compatibility notes.

## Execution Steps
1. Inventory public entry points and contracts; verify documented behaviors and invariants.
2. Check examples and snippets for freshness; run them if possible.
3. Align versioning, changelog entries, and migration guidance with actual changes.
4. Recommend documentation updates and missing artifacts (error sections, diagrams, compatibility notes).
5. Capture open questions and assign owners for clarification.

## Prompt Template
```
Act as the Discovery Analyst running the "Documentation and Contracts Review" scenario.
- List public APIs and confirm documented behaviors and invariants.
- Validate examples/snippets for freshness and accuracy.
- Recommend doc updates, migration guides, and clarifications.
```
