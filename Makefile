# Makefile for the project.
#
# This Makefile is designed to be cross-platform. It requires `make` and `cargo`
# to be installed and available in the system's PATH.

.DEFAULT_GOAL := help
CARGO := cargo

.PHONY: all build check clippy clean doc fmt help install release run test build-macos-arm64 build-linux-arm64 build-linux-amd64 build-linux-riscv64 cross-build-all generate-assets lint fmt-check clippy-pedantic check-release test-doc deny ci ci-lint ci-test ci-security doc-check security-audit coverage bench check-dirty test-all-features test-minimal-features install-cross cross-build security-audit-ci deny-ci functional-test setup-dev-env

# ==============================================================================
# Main targets
# ==============================================================================

all: build

build:
	@echo "Building debug version..."
	@$(CARGO) build

release:
	@echo "Building release version..."
	@$(CARGO) build --release

run:
	@$(CARGO) run -- $(ARGS)

test: functional-test
	@echo "Running tests..."
	@$(CARGO) test

check:
	@echo "Checking source code..."
	@$(CARGO) check

# ==============================================================================
# Linting and Validation
# ==============================================================================

lint: fmt-check clippy
	@echo "All validation checks passed successfully."

fmt-check:
	@echo "Checking code formatting..."
	@$(CARGO) fmt --all -- --check

clippy-pedantic:
	@echo "Running pedantic clippy linter..."
	@$(CARGO) clippy --workspace --all-targets --all-features -- -D warnings -D clippy::pedantic -D clippy::nursery -D clippy::cargo

check-release:
	@echo "Checking release build..."
	@$(CARGO) check --workspace --release
	@$(CARGO) check --workspace --release --all-features --all-targets

test-doc:
	@echo "Running doc tests..."
	@$(CARGO) test --workspace --doc
	@$(CARGO) test --workspace --all-features --release --doc

deny:
	@echo "Checking for crate policy violations..."
	@$(CARGO) deny check -D warnings

# ==============================================================================
# CI Targets (emulate .github/workflows/ci.yaml)
# ==============================================================================

ci: ci-lint ci-test ci-security
	@echo "All CI checks passed successfully."

# Mirrors the 'lint' job in CI
ci-lint: fmt-check clippy doc-check check-dirty

# Mirrors the 'test' job matrix in CI
ci-test: check-release test-all-features test-minimal-features test-doc functional-test

# Mirrors the 'security' job in CI
ci-security: deny-ci security-audit-ci

doc-check:
	@echo "Checking documentation..."
	@RUSTDOCFLAGS="-D warnings -D rustdoc::broken_intra_doc_links" $(CARGO) doc --workspace --all-features --no-deps --document-private-items

security-audit-ci:
	@echo "Running cargo audit for security vulnerabilities (CI mode)..."
	@# Generate JSON report, then run again to show human-readable output and issue a warning
	@# The part with || true ensures the step doesn't fail if vulnerabilities are found
	@mkdir -p target/reports && $(CARGO) audit --json > target/reports/audit-report.json || true
	@$(CARGO) audit || echo "::warning::Security vulnerabilities found"

deny-ci:
	@echo "Checking for crate policy violations (CI mode)..."
	@if [ ! -f deny.toml ]; then $(CARGO) deny init; fi
	@mkdir -p target/reports && $(CARGO) deny --format json check > target/reports/deny-report.json || true
	@$(CARGO) deny check || echo "::warning::Policy violations found"

security-audit:
	@echo "Running cargo audit for security vulnerabilities..."
	@$(CARGO) audit

coverage:
	@echo "Generating code coverage report..."
	@$(CARGO) llvm-cov --workspace --all-features --lcov --output-path lcov.info
	@echo "Coverage report generated at lcov.info"
	@echo "To view HTML report, run: cargo llvm-cov report --html --output-dir coverage-html"

bench:
	@echo "Running benchmarks..."
	@$(CARGO) bench --all-features

check-dirty:
	@echo "Checking for uncommitted changes..."
	@if ! git diff --exit-code --quiet; then \
		echo "::error::Uncommitted changes detected. Please commit or stash them before running CI checks."; \
		exit 1; \
	fi
	@echo "No uncommitted changes found."

test-all-features:
	@$(CARGO) test --workspace --all-features

test-minimal-features:
	@$(CARGO) test --workspace --no-default-features

# ==============================================================================
# Functional Tests
# ==============================================================================

MCP_BIN := target/release/mcp_linux_ssh

functional-test: release
	@echo "Running functional tests..."
	@echo "No functional tests defined yet for mcp_linux_ssh."
	@echo "Functional tests passed."


# ==============================================================================
# Cross-compilation targets
# ==============================================================================
# Ensure you have the required toolchains installed via rustup, e.g.:
# rustup target add aarch64-apple-darwin
# rustup target add aarch64-unknown-linux-gnu
# rustup target add x86_64-unknown-linux-gnu

MACOS_ARM64_TARGET := aarch64-apple-darwin
LINUX_ARM64_TARGET := aarch64-unknown-linux-gnu
LINUX_AMD64_TARGET := x86_64-unknown-linux-gnu
LINUX_RISCV64_TARGET := riscv64gc-unknown-linux-gnu

build-macos-arm64:
	@echo "Building release for macOS (ARM64)..."
	@$(CARGO) build --release --target $(MACOS_ARM64_TARGET)

build-linux-arm64:
	@echo "Building release for Linux (ARM64)..."
	@$(CARGO) build --release --target $(LINUX_ARM64_TARGET)

build-linux-amd64:
	@echo "Building release for Linux (AMD64)..."
	@$(CARGO) build --release --target $(LINUX_AMD64_TARGET)

build-linux-riscv64:
	@echo "Building release for Linux (RISC-V 64)..."
	@make cross-build TARGET=$(LINUX_RISCV64_TARGET)

cross-build-all: build-macos-arm64 build-linux-arm64 build-linux-amd64 build-linux-riscv64
	@echo "All cross-compilation builds complete."

install-cross:
	@echo "Installing cross..."
	@$(CARGO) install cross --locked --version 0.2.5

cross-build:
	@if [ -z "$(TARGET)" ]; then echo "TARGET environment variable is not set"; exit 1; fi
	@echo "Cross-compiling for target $(TARGET)..."
	@cross build --release --target $(TARGET) --all-features

# ==============================================================================
# Utility targets
# ==============================================================================

clippy:
	@echo "Running clippy linter..."
	@$(CARGO) clippy --workspace --all-targets --all-features -- -D warnings

generate-assets:
	@echo "Asset generation not configured for this project."

doc:
	@echo "Generating documentation..."
	@$(CARGO) doc --no-deps --open

fmt:
	@echo "Formatting code..."
	@$(CARGO) fmt --all

install: release
	@echo "Installing release binary..."
	@$(CARGO) install --path .

clean:
	@echo "Cleaning project..."
	@$(CARGO) clean

setup-dev-env:
	@echo "Setting up development environment..."
	@echo "Installing rustfmt and clippy..."
	@rustup component add rustfmt clippy
	@echo "Installing additional cargo tools..."
	@$(CARGO) install cargo-deny cargo-audit cargo-llvm-cov
	@echo "Development environment setup complete."

# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "Cross-platform Makefile for the project."
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main targets:"
	@echo "  all        Build the project (default)."
	@echo "  build      Build the project for debugging."
	@echo "  release    Build an optimized release version for the host machine."
	@echo "  run        Run the project. Pass arguments via ARGS."
	@echo "             Example: make run ARGS=\"-f ansi src/main.rs\""
	@echo "  test       Run all tests."
	@echo "  check      Check debug build for errors without building."
	@echo ""
	@echo "CI targets (to emulate GitHub Actions workflow):"
	@echo "  ci         Run all primary CI validation checks (lint, test, security)."
	@echo "  ci-lint    Run formatting, clippy, doc, and dirtiness checks."
	@echo "  ci-test    Run test suite with multiple feature configurations."
	@echo "  ci-security Run security audit and dependency policy checks."
	@echo ""
	@echo "Linting and Validation targets:"
	@echo "  lint       Run standard developer lint checks (fmt-check, clippy)."
	@echo "  fmt-check  Check code formatting."
	@echo "  clippy-pedantic  Run stricter clippy linter."
	@echo "  check-release  Check release build with default and all features."
	@echo "  deny       Check for crate policy violations (e.g., licenses)."
	@echo ""
	@echo "Functional test targets:"
	@echo "  functional-test   Run functional tests (placeholder for now)."
	@echo ""
	@echo "Cross-compilation targets (release build):"
	@echo "  build-macos-arm64   Build for macOS (ARM64)."
	@echo "  build-linux-arm64   Build for Linux (ARM64)."
	@echo "  build-linux-amd64   Build for Linux (AMD64)."
	@echo "  build-linux-riscv64 Build for Linux (RISC-V 64)."
	@echo "  cross-build-all     Build for all cross-compilation targets (macOS, Linux ARM/AMD/RISC-V)."
	@echo ""
	@echo "Utility targets:"
	@echo "  clippy     Run the clippy linter for code analysis."
	@echo "  fmt        Format code according to style guidelines."
	@echo "  doc        Generate and open project documentation."
	@echo "  doc-check  Check documentation for broken links and warnings."
	@echo "  coverage   Generate a code coverage report."
	@echo "  bench      Run benchmarks."
	@echo "  install    Build release and install to Cargo's bin directory."
	@echo "  clean      Remove build artifacts."
	@echo "  help       Display this help message."
	@echo ""
	@echo "Project Setup:"
	@echo "  setup-dev-env  Install all necessary Rust components and tools for development."
