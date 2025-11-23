---
id: build_and_ci_review
name: Build and CI/CD Review
description: Validate build reproducibility, matrix coverage, and pipeline safety.
tags: [ci, build, pipelines]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Build and CI/CD Review

## Goal
Confirm that builds are reproducible, efficient, and secured by CI/CD controls that match delivery needs.

## When to Use
- Pipeline failures or timeouts increase.
- New environments or architectures are being added.
- A user asks to inspect build or workflow quality.

## Inputs
- CI/CD workflow files and caching configuration.
- Build matrix (platforms, Rust versions, feature flags).
- Artifact publication steps and environment protections.

## Execution Steps
1. Read workflow definitions for coverage (fmt, check, clippy, tests, release artifacts) and caching strategy.
2. Verify version pinning for toolchains and actions; flag mutable tags.
3. Assess reproducibility: lockfiles, deterministic build flags, artifact signatures.
4. Identify security gaps: secret handling, permissions, branch protections, PR validation.
5. Recommend improvements: matrix adjustments, cache keys, gating tests, release sign-off.

## Prompt Template
```
Act as the DevOps Engineer running the "Build and CI/CD Review" scenario.
- Inspect workflows for coverage, caching, and version pinning.
- Evaluate reproducibility and artifact integrity.
- Call out security or permission gaps in pipelines.
- Deliver a concise list of fixes with expected impact.
```
