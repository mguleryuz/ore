# ORE Mining - Makefile
# Easy commands to setup and deploy blocks

.PHONY: help setup deploy build clean check-deps board miner treasury config round claim checkpoint reset test env generate-keypair balance address test-e2e test-e2e-verbose test-e2e-mainnet ensure-setup check-python

# Helper: Check if all dependencies are installed
_check_deps = command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1 && command -v solana >/dev/null 2>&1 && command -v bc >/dev/null 2>&1 && command -v pkg-config >/dev/null 2>&1 && [ -f .env ] && [ -f ./tmp/keypair.json ]

# Helper: Check if a command exists
_command_exists = command -v $(1) >/dev/null 2>&1

# Helper: Check Python and base58 dependencies
_check_python_deps = command -v python3 >/dev/null 2>&1 && python3 -c "import base58" >/dev/null 2>&1

# Helper: Ensure Python dependencies are available
check-python: check-solana
	@if ! command -v python3 >/dev/null 2>&1; then \
		echo "❌ Error: Python3 not found"; \
		echo ""; \
		echo "Run setup to install all dependencies:"; \
		echo "  make setup"; \
		exit 1; \
	fi
	@if ! python3 -c "import base58" >/dev/null 2>&1; then \
		echo "❌ Error: Python base58 library not installed"; \
		echo ""; \
		echo "Install with:"; \
		echo "  pip3 install base58"; \
		echo ""; \
		echo "Or run setup:"; \
		echo "  make setup"; \
		exit 1; \
	fi

# Helper: Ensure all dependencies are installed before running commands
ensure-setup:
	@if ! ($(call _check_deps)); then \
		echo "⚠️  Missing dependencies or configuration. Running setup..."; \
		./script/setup.sh; \
	fi

# Default target - show help
help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║              ORE Mining - Available Commands               ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Setup & Configuration:"
	@echo "  make setup          - Install dependencies and setup environment"
	@echo "  make env            - Create .env file from .env.example"
	@echo "  make check-deps     - Check if all dependencies are installed"
	@echo ""
	@echo "Building:"
	@echo "  make build          - Build the project in release mode"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make test           - Run unit tests"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy         - Auto-deploy to randomly selected available blocks"
	@echo ""
	@echo "Query Commands:"
	@echo "  make board          - Show current board state"
	@echo "  make miner          - Show miner information"
	@echo "  make treasury       - Show treasury information"
	@echo "  make config         - Show config information"
	@echo "  make round          - Show round information (requires ID=<number>)"
	@echo ""
	@echo "Transaction Commands:"
	@echo "  make claim          - Claim mining rewards (SOL + ORE)"
	@echo "  make checkpoint     - Checkpoint a miner (requires AUTHORITY=<pubkey>)"
	@echo "  make reset          - Reset the board for a new round"
	@echo ""
	@echo "E2E Testing:"
	@echo "  make test-e2e       - Run E2E integration tests"
	@echo "  make test-e2e-verbose - Run E2E tests with output"
	@echo "  make test-e2e-mainnet - Query mainnet for testing"
	@echo ""
	@echo "Wallet Management:"
	@echo "  make generate-keypair              - Generate new keypair (secure)"
	@echo "  make balance                       - Show wallet balance"
	@echo "  make address                       - Show wallet address"
	@echo ""
	@echo "Examples:"
	@echo "  make setup                                          - First time setup"
	@echo "  make deploy                                         - Deploy with .env config"
	@echo "  make generate-keypair                               - Generate new random keypair"
	@echo "  make generate-keypair base58_key                    - Import from base58 key"
	@echo "  make generate-keypair KEY=\"seedphrase words...\"    - Import from seedphrase (account 0)"
	@echo "  make generate-keypair KEY=\"seedphrase...\" ACCOUNT=1 - Import seedphrase account 1"
	@echo "  make round ID=123                             - Show round 123 info"
	@echo "  make checkpoint AUTHORITY=...                 - Checkpoint specific miner"
	@echo ""

# Setup - Install all dependencies
setup:
	@echo "🔧 Running setup script..."
	@chmod +x script/setup.sh
	@./script/setup.sh

# Auto-deploy to randomly selected blocks
deploy: ensure-setup
	@echo "🚀 Auto-deploying to randomly selected blocks..."
	@chmod +x script/auto_deploy.sh
	@./script/auto_deploy.sh

# Build the project
build:
	@echo "🔨 Building project..."
	@cargo build --release

# Build in debug mode
build-debug:
	@echo "🔨 Building project (debug mode)..."
	@cargo build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@cargo clean
	@echo "✅ Clean complete"

# Test the project
test:
	@echo "🧪 Running tests..."
	@cargo test --lib --release 2>&1 | grep -E "(test result|error|PASSED|FAILED)" || true

# Check if dependencies are installed
check-deps:
	@echo "🔍 Checking dependencies..."
	@command -v rustc >/dev/null 2>&1 && echo "✅ Rust installed: $$(rustc --version)" || echo "❌ Rust not installed"
	@command -v cargo >/dev/null 2>&1 && echo "✅ Cargo installed: $$(cargo --version)" || echo "❌ Cargo not installed"
	@command -v solana >/dev/null 2>&1 && echo "✅ Solana CLI installed: $$(solana --version)" || echo "❌ Solana CLI not installed"
	@command -v bc >/dev/null 2>&1 && echo "✅ bc installed" || echo "❌ bc not installed"
	@command -v pkg-config >/dev/null 2>&1 && echo "✅ pkg-config installed" || echo "❌ pkg-config not installed"
	@echo ""
	@if [ -f .env ]; then echo "✅ .env file exists"; else echo "⚠️  .env file not found"; fi

# Create .env from .env.example
env:
	@if [ -f .env ]; then \
		echo "⚠️  .env file already exists. Not overwriting."; \
		echo "   Delete .env first if you want to recreate it."; \
	elif [ -f .env.example ]; then \
		cp .env.example .env; \
		echo "✅ Created .env from .env.example"; \
		echo "⚠️  Please edit .env with your configuration"; \
	else \
		echo "❌ .env.example not found"; \
		exit 1; \
	fi

# Query commands using the CLI
board: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="board" && \
		cargo run --release --bin ore-cli

miner: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="miner" && \
		cargo run --release --bin ore-cli

treasury: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="treasury" && \
		cargo run --release --bin ore-cli

config: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="config" && \
		cargo run --release --bin ore-cli

round: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@if [ -z "$(ID)" ]; then echo "❌ ID parameter required. Usage: make round ID=123"; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="round" && \
		export ID=$(ID) && \
		cargo run --release --bin ore-cli

clock: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="clock" && \
		cargo run --release --bin ore-cli

stake: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="stake" && \
		cargo run --release --bin ore-cli

# Transaction commands
claim: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@echo "💰 Claiming rewards..."
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="claim" && \
		cargo run --release --bin ore-cli

checkpoint: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@if [ -z "$(AUTHORITY)" ]; then \
		echo "⚠️  No AUTHORITY specified, using keypair pubkey..."; \
		export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="checkpoint" && \
		cargo run --release --bin ore-cli; \
	else \
		echo "📍 Checkpointing miner: $(AUTHORITY)"; \
		export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="checkpoint" && \
		export AUTHORITY=$(AUTHORITY) && \
		cargo run --release --bin ore-cli; \
	fi

checkpoint-all: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@echo "📍 Checkpointing all miners..."
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="checkpoint_all" && \
		cargo run --release --bin ore-cli

reset: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@echo "🔄 Resetting board..."
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="reset" && \
		cargo run --release --bin ore-cli

# Install Solana CLI specifically
install-solana:
	@echo "📥 Installing Solana CLI..."
	@sh -c "$$(curl -sSfL https://release.solana.com/stable/install)"
	@echo "✅ Solana CLI installed. You may need to restart your terminal."

# Install Rust specifically
install-rust:
	@echo "📥 Installing Rust..."
	@curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	@echo "✅ Rust installed. Run 'source ~/.cargo/env' or restart your terminal."

# Format code
fmt:
	@echo "🎨 Formatting code..."
	@cargo fmt

# Check code formatting
fmt-check:
	@echo "🔍 Checking code formatting..."
	@cargo fmt -- --check

# Run clippy (linter)
lint:
	@echo "🔍 Running clippy..."
	@cargo clippy -- -D warnings

# Update dependencies
update:
	@echo "📦 Updating dependencies..."
	@cargo update

# Show wallet balance
balance: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		solana balance --keypair $$PRIVATE_KEY_PATH --url $$RPC_URL

# Show wallet address
address: ensure-setup
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		solana address --keypair $$PRIVATE_KEY_PATH

# Generate new keypair (secure, no history)
# Usage: make generate-keypair KEY="..." ACCOUNT=N
# Or: make generate-keypair [simple_arg]
# Examples: 
#   make generate-keypair                        - Generate random keypair
#   make generate-keypair KEY="seedphrase"       - Import seedphrase (account 0)
#   make generate-keypair KEY="seedphrase" ACCOUNT=1 - Import seedphrase account 1
#   make generate-keypair base58_key             - Import base58 key
generate-keypair: check-python
	@echo "🔐 Generating Solana keypair..."
	@chmod +x script/generate_keypair.sh
	@if [ -n "$(KEY)" ]; then \
		./script/generate_keypair.sh "$(KEY)" "$(ACCOUNT)"; \
	else \
		FIRST_ARG="$(wordlist 2,2,$(MAKECMDGOALS))"; \
		if [ -n "$$FIRST_ARG" ]; then \
			./script/generate_keypair.sh "$$FIRST_ARG" "$(wordlist 3,3,$(MAKECMDGOALS))"; \
		else \
			./script/generate_keypair.sh; \
		fi; \
	fi

# Check if Solana CLI is installed
check-solana:
	@if ! command -v solana-keygen &> /dev/null; then \
		echo "❌ Error: Solana CLI not found"; \
		echo ""; \
		echo "Run setup first to install all dependencies:"; \
		echo "  make setup"; \
		exit 1; \
	fi

# Catch-all rule for generate-keypair arguments (prevents "No rule to make target" errors)
%:
	@:

# Quick start guide
quickstart:
	@if [ -f spec/QUICKSTART.md ]; then \
		cat spec/QUICKSTART.md; \
	else \
		echo "❌ spec/QUICKSTART.md not found"; \
	fi

# E2E Testing
test-e2e:
	@echo "🧪 Running E2E integration tests..."
	@cd test && cargo test --release

test-e2e-verbose:
	@echo "🧪 Running E2E tests with verbose output..."
	@cd test && cargo test --release -- --nocapture

test-e2e-mainnet:
	@echo "🧪 Running mainnet query tests..."
	@cd test && cargo test --release test_query_available_blocks -- --nocapture --ignored

