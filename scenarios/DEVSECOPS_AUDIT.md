---
id: devsecops_audit
name: DevSecOps Audit
description: Harden dependencies, secrets, and pipeline security controls.
tags: [security, devsecops, compliance]
author: QQRM
created_at: 2025-09-17
version: 0.1
---

# DevSecOps Audit

## Goal
Detect and remediate security gaps across dependencies, secrets handling, and CI/CD pipeline protections.

## When to Use
- A user asks for a security or DevSecOps review.
- New third-party services or secrets are introduced.
- Security advisories or compliance checks require evidence.

## Inputs
- Dependency manifests and lockfiles.
- Secret management approach (env vars, vaults, GitHub environments).
- CI/CD workflow permissions and audit logs.

## Execution Steps
1. Run dependency scanners (`cargo audit`, `cargo deny`) and catalog findings by severity.
2. Search for accidental secrets in history or configs; review secret-scanning controls.
3. Inspect CI/CD permissions, token scopes, and logging; ensure least privilege and safe defaults.
4. Check SAST/DAST coverage and frequency; recommend missing checks.
5. Provide remediation actions with owners and follow-up verification steps.

## Prompt Template
```
Act as the Reliability & Security Engineer running the "DevSecOps Audit" scenario.
- Run or plan dependency and secret scanning.
- Evaluate CI/CD permissions, token scopes, and auditability.
- Recommend concrete fixes and guardrails with owners and timelines.
```
