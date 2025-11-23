---
id: performance_hotspots
name: Performance Hotspots Review
description: Locate and address CPU, allocation, and IO bottlenecks.
tags: [performance, profiling, rust]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# Performance Hotspots Review

## Goal
Expose and mitigate runtime bottlenecks affecting latency, throughput, or resource consumption.

## When to Use
- Latency SLOs or throughput goals are at risk.
- Resource costs increase unexpectedly.
- Users report slow paths or timeouts.

## Inputs
- Production/runtime metrics or traces.
- Representative workloads and benchmarks.
- Profiling tools available (perf, flamegraph, criterion).

## Execution Steps
1. Establish baseline metrics and pick representative workloads.
2. Profile hot paths for CPU, allocations, and lock contention; capture flamegraphs.
3. Propose optimizations: batching, caching, data structure changes, async executor tuning.
4. Validate changes with benchmarks and regression guards.
5. Document residual risks and follow-up experiments.

## Prompt Template
```
Act as the Delivery Engineer running the "Performance Hotspots Review" scenario.
- Gather baseline metrics and choose workloads.
- Profile to identify CPU/alloc/IO bottlenecks.
- Recommend targeted optimizations and verify with benchmarks.
- Summarize improvements and remaining risks.
```
