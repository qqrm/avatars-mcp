---
id: test_coverage
name: Test Coverage Review
description: Evaluate test depth, flakiness, and coverage gaps.
tags: [testing, quality, coverage]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Test Coverage Review

## Goal
Measure and improve automated test coverage, focusing on risky code paths and stable feedback loops.

## When to Use
- A user asks to check or raise test coverage.
- Recent regressions point to untested areas.
- New features land without integration tests.

## Inputs
- Locations of unit and integration tests.
- Coverage tooling (tarpaulin, grcov) and baseline reports.
- Flake records or unstable test suites.

## Execution Steps
1. Inventory existing tests by module and risk area; flag critical paths without coverage.
2. Run coverage tooling and capture reports; identify low-signal or flaky suites.
3. Recommend new tests and refactors to improve determinism (fixtures, hermetic setups, property tests).
4. Define acceptance criteria for coverage deltas and regression guards.
5. Summarize findings with a prioritized backlog of test additions.

## Prompt Template
```
Act as the Quality Engineer running the "Test Coverage Review" scenario.
- Map current tests to critical flows and note gaps.
- Execute coverage tooling and interpret the results.
- Propose specific tests (unit/integration/property) to close gaps and reduce flakiness.
- Provide a short plan to reach the target coverage safely.
```
