# Tooling Reference

This repository ships a small toolbelt that aligns with the GitHub Pages publishing flow and the Rust workspace under `/crates/`. Use these utilities to keep local workflows close to CI expectations.

## Rust-centric utilities

| Tool | Purpose |
| --- | --- |
| `cargo-make` | Task runner for chaining the validation steps defined in `README.md` and repository-specific workflows. |
| `cargo-watch` | Re-runs commands such as `cargo check` or `cargo test` on file changes to speed up feedback loops. |
| `cargo-edit` | Adds, removes, and updates dependencies directly from the CLI to keep manifests consistent. |
| `cargo-nextest` | Parallel test runner that mirrors the CI setup when repositories opt into faster feedback cycles. |
| `cargo-audit` | Scans dependency trees for known vulnerabilities before publishing persona updates. |
| `proptest` | Property-based testing harness for validating catalog parsing and other pure logic. |
| `cargo-fuzz` | Fuzzes CLI binaries under `crates/` to harden catalog generators against malformed inputs. |
| `cargo-tarpaulin` | Collects Rust code coverage for the generator workspace. |

## Documentation and diagrams

| Tool | Purpose |
| --- | --- |
| `mdBook` | Renders multi-page documentation sites from Markdown when repositories choose that format. |
| `typst` | Generates PDF artifacts for persona or scenario briefs. |
| `zola` | Static site generator alternative for documentation bundles. |
| `svgbob` | Converts ASCII diagrams into SVG assets for inclusion in Markdown. |

## Terminal productivity

| Tool | Purpose |
| --- | --- |
| `gitui` | Terminal UI for staging and reviewing changes. |
| `delta` | Syntax-highlighted diff viewer for readable reviews. |
| `helix` | Modal terminal editor with built-in LSP support. |
| `zellij` | Terminal workspace manager and multiplexing alternative. |
| `fd` | Fast file finder useful for locating personas and scenarios. |
| `bat` | `cat` replacement with syntax highlighting for quick doc reviews. |
| `ripgrep` | High-performance search for scanning Markdown instructions and personas. |

## Candidates for baseline instructions

The following utilities provide the most cross-repository value and are candidates for inclusion in the shared `AGENTS.md` guidance:

- `cargo-make`, `cargo-watch`, and `cargo-edit` for consistent task orchestration and manifest hygiene.
- `cargo-nextest` and `cargo-audit` to accelerate and harden validation loops alongside standard Rust checks.
- `mdBook` and `svgbob` to keep documentation and diagrams up to date without bespoke tooling.
- `delta`, `gitui`, `fd`, `bat`, and `ripgrep` to speed up reviews and repository navigation.
