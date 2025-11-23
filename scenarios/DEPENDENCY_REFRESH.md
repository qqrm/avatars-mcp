---
id: dependency_refresh
name: Dependency and Toolchain Refresh
description: Verify Rust toolchain pinning and refresh crate versions with safe updates.
tags: [maintenance, dependencies, rust]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Dependency and Toolchain Refresh

## Goal
Keep the Rust toolchain, crates, and lockfiles on supported, current versions without breaking builds.

## When to Use
- A user requests dependency or toolchain updates.
- Security advisories mention vulnerable crates.
- CI starts failing due to compiler or crate deprecations.

## Inputs
- Location of `rust-toolchain.toml` or `rust-toolchain`.
- `Cargo.toml` and `Cargo.lock` for every crate.
- Existing CI matrix and minimal supported Rust version policy.

## Execution Steps
1. Confirm the pinned Rust channel and compare with the latest stable release.
2. Enumerate crates with available patch/minor updates and note breaking major jumps.
3. Apply targeted updates (security first), refreshing the lockfile deterministically.
4. Re-run the full Rust validation loop (fmt, check, clippy, tests, release build).
5. Record notable deltas (MSRV shifts, feature flag changes, dependency removals).

## Prompt Template
```
Act as the Delivery Engineer running the "Dependency and Toolchain Refresh" scenario.
- Locate rust-toolchain config and compare to latest stable.
- List crates needing updates, prioritizing security/patch releases.
- Propose a minimal, reversible update plan and call out MSRV impacts.
- After updates, rerun fmt/check/clippy/test/release build and summarize outcomes.
```
