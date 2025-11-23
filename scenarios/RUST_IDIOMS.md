---
id: rust_idioms
name: Rust Idioms Review
description: Enforce idiomatic Rust patterns and modern language features.
tags: [rust, quality, idioms]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Rust Idioms Review

## Goal
Ensure the codebase uses modern, idiomatic Rust patterns that improve safety, readability, and performance.

## When to Use
- The user asks to check for idiomatic Rust usage.
- Recent Rust releases add features the codebase could adopt.
- Clippy or reviews repeatedly flag style and ownership issues.

## Inputs
- Current Rust edition and toolchain channel.
- Clippy configuration and lint baselines.
- Areas with known ownership/borrowing complexity.

## Execution Steps
1. Scan for anti-patterns: needless clones, manual loops vs. iterators, unclear lifetimes, error handling shortcuts.
2. Run `cargo clippy --all-targets --all-features -- -D warnings` and triage findings.
3. Propose idiomatic replacements: iterator combinators, `?`/`Result`, `From/Into`, `serde` derives, async best practices.
4. Highlight Rust-version-enabled improvements (e.g., let-else, `async fn` in traits when stable, pattern matching ergonomics).
5. Summarize recommendations with examples and expected impact.

## Prompt Template
```
Act as the Delivery Engineer running the "Rust Idioms Review" scenario.
- Identify unidiomatic Rust patterns and clippy violations.
- Recommend idiomatic rewrites and language features available on the pinned toolchain.
- Note ownership/borrowing pain points and safer APIs.
- Produce a prioritized remediation checklist.
```
