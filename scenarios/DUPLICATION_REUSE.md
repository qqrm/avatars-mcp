---
id: duplication_reuse
name: Duplication and Reuse Review
description: Find repeated logic and consolidate shared capabilities.
tags: [refactoring, reuse, quality]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Duplication and Reuse Review

## Goal
Reduce duplicated code and inconsistent implementations by extracting shared abstractions.

## When to Use
- The codebase shows similar functions or modules across services.
- Bugs recur due to divergent implementations.
- A user asks to consolidate utilities or patterns.

## Inputs
- Module/function inventory and naming conventions.
- Known areas with repeated logic or templates.
- Existing shared crates or utilities.

## Execution Steps
1. Search for similar functions, modules, or API shapes; group them by behavior.
2. Compare differences to isolate true divergence vs. accidental drift.
3. Propose consolidation: shared crates, traits, templates, or configuration deduplication.
4. Outline migration steps with regression tests and rollout order.
5. Track residual exceptions and rationale.

## Prompt Template
```
Act as the Solution Architect running the "Duplication and Reuse Review" scenario.
- Locate repeated logic and compare differences.
- Recommend consolidation paths (shared crates/traits/templates) with migration safety.
- Provide a rollout plan with validation steps and owners.
```
