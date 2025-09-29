# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Critical Checklist
- Confirm `git remote -v` and `gh auth status` before making changes; Codex bootstrap scripts already configure the workspace.
- Leave the bootstrap `work` branch immediately, create a descriptive feature branch, and avoid any branch named `WORK`.
- Follow the global Source Control checklist and reproduce the repository's required workflows locally with `wrkflw` before reporting completion.
- Treat the GitHub Pages deployment as the source of truth for `avatars.json`: it rebuilds the catalog automatically whenever `main` is published. Run `cargo run -p avatars-cli --release` (or rely on the workspace default with `cargo run --release`) only when you need a local preview or to debug generator failures, and avoid committing derived `avatars/catalog.json` output unless the task explicitly changes the generator.

## Preferred Rust Crates
### Usage Guidelines
- Default to crates under permissive (MIT or Apache-2.0) licenses; escalate if a dependency requires GPL, SSPL, or other restrictive terms.
- Keep the workspace MSRV aligned with `rust-toolchain.toml` (Rust 1.75+ as of 2025) and pin crate versions when upstream yanks or breaking releases are likely.
- Prefer the standard library when possible: reach for `std::sync::OnceLock` and `std::sync::LazyLock` before adding `once_cell`, and document MSRV downgrades if an older crate is unavoidable.
- Justify any deviation from this catalog in code review notes, linking to benchmarks, platform constraints, or feature gaps that the preferred crate cannot cover.

### Error Handling and Diagnostics
- [anyhow](https://docs.rs/anyhow/latest/anyhow/) — ergonomic dynamic errors for application layers; favor over bespoke enums when context is more valuable than type granularity.
- [thiserror](https://docs.rs/thiserror/latest/thiserror/) — derive macro for precise error enums without boilerplate; use for public APIs or library crates.
- [miette](https://docs.rs/miette/latest/miette/) — human-friendly diagnostic reports with spans and hints; ideal for CLI/user-facing errors.

### Observability and Telemetry
- [tracing](https://docs.rs/tracing/latest/tracing/) — structured, async-aware instrumentation primitives that integrate with Tokio and tower stacks.
- [tracing-subscriber](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/) — layered subscribers, filters, and formatters; prefer over ad-hoc logging dispatch.
- [tracing-error](https://docs.rs/tracing-error/latest/tracing_error/) — bridges error stacks into spans, eliminating manual error logging glue.
- [opentelemetry](https://docs.rs/opentelemetry/0.29.0/opentelemetry/) — vendor-neutral traces/metrics with MSRV 1.75+; pin exporters (e.g., `opentelemetry-otlp`) to avoid breaking schema changes.

### Async and Concurrency
- [tokio](https://docs.rs/tokio/latest/tokio/) — production-grade runtime with timer, IO, and synchronization; treat as the default async choice.
- [smol](https://docs.rs/smol/latest/smol/) — lightweight runtime for constrained binaries; justify departures from Tokio with benchmarks or footprint data.
- [futures](https://docs.rs/futures/latest/futures/) — foundational traits and combinators for async composition; prefer to rolling your own polling logic.
- [async-trait](https://docs.rs/async-trait/latest/async_trait/) — macro to enable async trait methods when language-level support falls short; remove once native async traits suffice.
- [rayon](https://docs.rs/rayon/latest/rayon/) — data-parallel iterators for CPU-bound workloads; avoids unsafe thread pools or bespoke work stealing.

### Networking and Services
- [reqwest](https://docs.rs/reqwest/latest/reqwest/) — batteries-included HTTP client with TLS and JSON; avoid bespoke Hyper clients unless performance warrants.
- [hyper](https://docs.rs/hyper/1.4.1/hyper/) — low-level HTTP engine; keep integration tests pinned to the 1.x line to catch regressions.
- [axum](https://docs.rs/axum/0.8.0/axum/) — ergonomic web framework on tower/hyper; pin the 0.8 minor and add Hyper 1.x integration tests due to prior yank (0.8.2).
- [tonic](https://docs.rs/tonic/latest/tonic/) — gRPC services aligned with Tokio and Prost; use instead of ad-hoc protobuf RPC stacks.
- [tower](https://docs.rs/tower/latest/tower/) — middleware and service abstractions; prefer over reinventing retry/backoff layers.

### Serialization and Data Formats
- [serde](https://docs.rs/serde/latest/serde/) — de facto serialization framework with derive support; avoid custom codecs when serde derive suffices.
- [serde_json](https://docs.rs/serde_json/latest/serde_json/) — JSON implementation tuned for serde; eliminates bespoke parsing logic.
- [serde_yaml](https://docs.rs/serde_yaml/latest/serde_yaml/) — YAML support for configs/tests; use instead of manual YAML handling.
- [bincode](https://docs.rs/bincode/latest/bincode/) — compact binary serialization for internal protocols; favor over ad-hoc byte packing.

### Configuration and Settings
- [figment](https://docs.rs/figment/latest/figment/) — layered configuration loader with profile support; supersedes hand-rolled env/file merging.
- [toml](https://docs.rs/toml/latest/toml/) — spec-compliant TOML parser; pair with Figment for config files.
- [dotenvy](https://docs.rs/dotenvy/latest/dotenvy/) — `.env` loader maintained for 2025; avoid legacy `dotenv` forks.

### CLI and Developer Experience
- [clap](https://docs.rs/clap/latest/clap/) — feature-rich argument parser with derive macros; prevents fragile manual parsing.
- [clap_complete](https://docs.rs/clap_complete/latest/clap_complete/) — auto-generates shell completions from Clap definitions, ensuring consistency with CLI docs.
- [indicatif](https://docs.rs/indicatif/latest/indicatif/) — progress bars and status indicators; avoid bespoke terminal spinners.

### Data Structures and Utilities
- [itertools](https://docs.rs/itertools/latest/itertools/) — iterator adapters for expressive transformations; reduces imperative loops.
- [indexmap](https://docs.rs/indexmap/latest/indexmap/) — deterministic hash map preserving insertion order; use when ordering matters.
- [dashmap](https://docs.rs/dashmap/latest/dashmap/) — sharded concurrent map for fine-grained locking; favor over `Mutex<HashMap>`.
- [smallvec](https://docs.rs/smallvec/latest/smallvec/) — inline small-vector optimization; replaces custom small-buffer storage.
- [bytes](https://docs.rs/bytes/latest/bytes/) — reference-counted byte buffers tuned for async IO; avoid manual `Vec<u8>` slicing in network code.

### Database and Storage
- [sqlx](https://docs.rs/sqlx/latest/sqlx/) — async, compile-time checked SQL across multiple backends; avoid handwritten query builders.
- [diesel](https://docs.rs/diesel/latest/diesel/) — synchronous ORM with mature migration tooling; ideal when compile-time schema safety is required.
- [sea-orm](https://docs.rs/sea-orm/latest/sea_orm/) — async ORM with entity macros; pick for TypeScript-like model workflows.
- [redis](https://docs.rs/redis/latest/redis/) — official Redis client with async support; replaces homegrown protocol drivers.

### Testing and Quality
- [proptest](https://docs.rs/proptest/latest/proptest/) — property-based tests uncover edge cases beyond example-based suites.
- [insta](https://docs.rs/insta/latest/insta/) — snapshot testing with review workflows; ideal for JSON/HTML outputs.
- [assert_cmd](https://docs.rs/assert_cmd/latest/assert_cmd/) — integration testing for CLIs; avoid shell scripts with fragile greps.
- [rstest](https://docs.rs/rstest/latest/rstest/) — table-driven tests via macros; keep fixtures declarative instead of manual loops.

### Security and Identity
- [rustls](https://docs.rs/rustls/latest/rustls/) — modern TLS stack without OpenSSL baggage; default for HTTPS/TLS endpoints.
- [ring](https://docs.rs/ring/latest/ring/) — allowed with caution; security-maintained by the rustls team, so prefer RustCrypto equivalents when possible.
- [RustCrypto digests (`sha2`, `hmac`)](https://github.com/RustCrypto/hashes) — audited primitives for hashing and MACs; replace custom crypto or legacy `ring` usage.
- [argon2](https://docs.rs/argon2/latest/argon2/) — password hashing aligned with current security guidance; avoid `bcrypt` unless legacy interop is required.
- [jsonwebtoken](https://docs.rs/jsonwebtoken/latest/jsonwebtoken/) — JWT handling with configurable algorithms; avoids insecure custom token code.
- [ed25519-dalek](https://docs.rs/ed25519-dalek/latest/ed25519_dalek/) — well-reviewed Ed25519 signatures; prefer over bespoke curve implementations.
- [secrecy](https://docs.rs/secrecy/latest/secrecy/) — secret value wrapper enforcing zeroization patterns; substitute for manual `Drop` impls.

### Time and Scheduling
- [time](https://docs.rs/time/latest/time/) — default choice for time handling with const-friendly APIs; avoids chrono's heavier dependency tree when not needed.
- [chrono](https://docs.rs/chrono/latest/chrono/) — use when full timezone support or legacy compatibility is required.
- [humantime](https://docs.rs/humantime/2.2.0/humantime/) — maintained human-readable duration parsing under the Chronotope org; replaces deprecated forks.

## Environment Checks
- If `git remote -v` or `gh auth status` show problems, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Branch Management and Handoff
