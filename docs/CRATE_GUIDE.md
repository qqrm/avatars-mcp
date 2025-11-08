# Crate Guide

This document tracks the crates Codex Tools prefers across the workspace. Each entry summarises why the crate is included and when to reach for it during development.

## Usage Guidelines
- Default to permissively licensed crates (MIT or Apache-2.0) and raise an issue when a dependency requires restrictive terms.
- Keep the minimum supported Rust version aligned with `rust-toolchain.toml` (Rust 1.75+ as of 2025) and pin versions when upstreams publish breaking changes.
- Prefer the standard library over external dependencies when it can cover the use case (for example, `std::sync::OnceLock` / `LazyLock` instead of `once_cell`).
- Document any intentional deviations from this list with performance data or missing features to streamline reviews.

## Error Handling and Diagnostics
- **anyhow** — ergonomic application-layer errors with context when type granularity is unnecessary.
- **thiserror** — derive macro for structured error enums suited to public APIs.
- **miette** — human-friendly diagnostic reports with spans and hints; ideal for CLI and user-facing output.

## Observability and Telemetry
- **tracing** — structured, async-aware instrumentation that integrates cleanly with Tokio and tower stacks.
- **tracing-subscriber** — layered subscribers, filters, and formatters; preferred over ad-hoc logging dispatch.
- **tracing-error** — bridges error stacks into spans to remove manual logging glue.
- **opentelemetry** — vendor-neutral traces and metrics; pin exporters such as `opentelemetry-otlp` to avoid schema surprises.

## Async and Concurrency
- **tokio** — production-grade async runtime with timers, IO, and synchronisation primitives.
- **smol** — lightweight runtime for constrained binaries; choose it only with footprint data to justify leaving Tokio.
- **futures** — foundational async traits and combinators; avoid hand-rolled polling logic.
- **async-trait** — macro that enables async trait methods until native support suffices.
- **rayon** — data-parallel iterators for CPU-bound workloads without bespoke thread pools.

## Networking and Services
- **reqwest** — batteries-included HTTP client with TLS and JSON support.
- **hyper** — low-level HTTP engine; keep integration tests pinned to 1.x to catch regressions.
- **axum** — ergonomic web framework on tower/hyper; pin the 0.8 minor and test Hyper 1.x integration.
- **tonic** — gRPC services aligned with Tokio and Prost; replaces ad-hoc protobuf stacks.
- **tower** — middleware and service abstractions; prefer it over reinventing retry/backoff layers.

## Serialization and Data Formats
- **serde** — de facto serialization framework with derive support; use instead of custom codecs.
- **serde_json** — tuned JSON support for serde; replaces manual parsing.
- **serde_yaml** — YAML handling for configs and tests.
- **bincode** — compact binary serialization for internal protocols.

## Configuration and Settings
- **figment** — layered configuration loader with profile support, replacing hand-rolled env/file merging.
- **toml** — spec-compliant TOML parser that pairs well with Figment.
- **dotenvy** — actively maintained `.env` loader; avoid legacy forks.

## CLI and Developer Experience
- **clap** — feature-rich argument parser with derive macros.
- **clap_complete** — generates shell completions directly from Clap definitions.
- **indicatif** — progress bars and status indicators; avoids bespoke terminal spinners.

## Data Structures and Utilities
- **itertools** — iterator adapters for expressive transformations that reduce imperative loops.
- **indexmap** — deterministic hash map preserving insertion order for cases where ordering matters.
- **dashmap** — sharded concurrent map for fine-grained locking; prefer over `Mutex<HashMap>`.
- **smallvec** — inline small-vector optimisation to avoid heap allocations for small collections.
- **bytes** — reference-counted byte buffers tuned for async IO.

## Database and Storage
- **sqlx** — async, compile-time checked SQL across multiple backends; avoids handwritten query builders.
- **diesel** — synchronous ORM with mature migration tooling and compile-time schema safety.
- **sea-orm** — async ORM with entity macros; mirrors TypeScript-like model workflows.
- **redis** — official Redis client with async support, replacing home-grown protocol drivers.

## Testing and Quality
- **proptest** — property-based tests that uncover edge cases beyond example-based suites.
- **insta** — snapshot testing with review workflows, ideal for JSON and HTML outputs.
- **assert_cmd** — integration testing for CLIs without fragile shell scripts.
- **rstest** — table-driven tests with declarative fixtures instead of manual loops.

## Security and Identity
- **rustls** — modern TLS stack without OpenSSL baggage; default for HTTPS/TLS endpoints.
- **ring** — security-maintained by the rustls team; choose RustCrypto alternatives when possible.
- **RustCrypto digests (`sha2`, `hmac`)** — audited primitives for hashing and MACs; replace custom crypto.
- **argon2** — current password hashing guidance; avoid `bcrypt` unless legacy interop is required.
- **jsonwebtoken** — configurable JWT handling with sane defaults; prevents insecure bespoke tokens.
- **ed25519-dalek** — well-reviewed Ed25519 signatures; avoid custom curve implementations.
- **secrecy** — secret value wrapper enforcing zeroisation patterns.

## Time and Scheduling
- **time** — default choice for time handling with const-friendly APIs.
- **chrono** — use when full timezone support or legacy compatibility is required.
- **humantime** — maintained human-readable duration parsing under the Chronotope organisation.
