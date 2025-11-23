---
id: developer_experience
name: Developer Experience Review
description: Improve onboarding, local workflows, and inner-loop speed.
tags: [dx, productivity, tooling]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Developer Experience Review

## Goal
Streamline how contributors build, test, and debug the project, reducing friction in the inner development loop.

## When to Use
- Onboarding takes too long or requires tribal knowledge.
- Local builds/tests are slow or flaky.
- A user asks for a smoother developer workflow.

## Inputs
- Bootstrap scripts, Makefiles/justfiles, `cargo xtask` helpers.
- Documentation for local setup and troubleshooting.
- Pain points reported by contributors.

## Execution Steps
1. Walk through the setup flow; note missing prerequisites, unstable steps, or unclear docs.
2. Profile inner-loop latency (build, test, lint) and identify caching or watch-mode opportunities.
3. Recommend automation: task runners, pre-commit hooks, template configs, sample env files.
4. Improve documentation: quickstart, debugging tips, common failures.
5. Define success metrics (time-to-first-build, lint/test shortcuts) and follow-up checks.

## Prompt Template
```
Act as the Delivery Engineer running the "Developer Experience Review" scenario.
- Reproduce the onboarding path and record friction.
- Suggest automation and tooling to speed up builds/tests/lints.
- Provide documentation improvements and success metrics.
```
