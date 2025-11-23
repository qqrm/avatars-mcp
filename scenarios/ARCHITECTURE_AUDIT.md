---
id: architecture_audit
name: Architecture Audit
description: Review modular boundaries, dependencies, and flexibility risks.
tags: [architecture, design, rust]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Architecture Audit

## Goal
Identify structural risks—tight coupling, unclear contracts, and brittle seams—and propose refactors that simplify and harden the system.

## When to Use
- A user asks for an architecture or design review.
- New features are slowed by cross-cutting dependencies.
- Incidents trace back to unclear ownership or contracts.

## Inputs
- Module layout and domain boundaries.
- Dependency graph (internal crates, feature flags, external crates).
- Non-functional requirements: scalability, observability, resilience.

## Execution Steps
1. Map core domains, interfaces, and data flows; highlight cyclic or high-fan-out dependencies.
2. Inspect module responsibilities for SRP/SoC adherence and boundary clarity.
3. Evaluate extension points (traits, adapters, feature gates) and migration safety.
4. Recommend targeted refactors: decomposition, facades, anti-corruption layers, or interface checklists.
5. Summarize risks, mitigations, and sequencing for incremental delivery.

## Prompt Template
```
Act as the Solution Architect running the "Architecture Audit" scenario.
- Diagram major modules/domains and their dependencies.
- Flag cycles, heavy abstractions, or leaky interfaces.
- Suggest refactors (boundaries, traits, adapters) and a safe rollout plan.
- Capture risks, ownership gaps, and follow-up actions.
```
