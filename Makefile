.PHONY: fmt check clippy lint test build-release docs qa catalog

fmt:
	cargo fmt --all -- --check

check:
	cargo check --tests --benches

clippy lint:
	cargo clippy --all-targets --all-features -- -D warnings

build-release:
	cargo build --release

test:
	cargo test

catalog:
	cargo run --release -p personas-core

docs:
	./scripts/build-pages.sh
	./scripts/validate-pages.sh

qa: fmt check clippy build-release test docs
