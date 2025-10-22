# ORE Mining - Makefile
# Easy commands to setup and deploy blocks

.PHONY: help setup deploy build clean check-deps board miner treasury config round claim checkpoint reset test install env

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
	@echo "  make test           - Run tests"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy         - Deploy to selected blocks (main script)"
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
	@echo "Examples:"
	@echo "  make setup                    - First time setup"
	@echo "  make deploy                   - Deploy with .env config"
	@echo "  make round ID=123             - Show round 123 info"
	@echo "  make checkpoint AUTHORITY=... - Checkpoint specific miner"
	@echo ""

# Setup - Install all dependencies
setup:
	@echo "🔧 Running setup script..."
	@chmod +x setup.sh
	@./setup.sh

# Deploy to selected blocks
deploy:
	@echo "🚀 Deploying to selected blocks..."
	@chmod +x select_blocks.sh
	@./select_blocks.sh

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
	@cargo test-sbf

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
board:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="board" && \
		cargo run --release --bin ore-cli

miner:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="miner" && \
		cargo run --release --bin ore-cli

treasury:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="treasury" && \
		cargo run --release --bin ore-cli

config:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="config" && \
		cargo run --release --bin ore-cli

round:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@if [ -z "$(ID)" ]; then echo "❌ ID parameter required. Usage: make round ID=123"; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="round" && \
		export ID=$(ID) && \
		cargo run --release --bin ore-cli

clock:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="clock" && \
		cargo run --release --bin ore-cli

stake:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="stake" && \
		cargo run --release --bin ore-cli

# Transaction commands
claim:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@echo "💰 Claiming rewards..."
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="claim" && \
		cargo run --release --bin ore-cli

checkpoint:
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

checkpoint-all:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@echo "📍 Checkpointing all miners..."
	@export $$(cat .env | grep -v '^#' | xargs) && \
		export KEYPAIR=$$PRIVATE_KEY_PATH && \
		export RPC=$$RPC_URL && \
		export COMMAND="checkpoint_all" && \
		cargo run --release --bin ore-cli

reset:
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
balance:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		solana balance --keypair $$PRIVATE_KEY_PATH --url $$RPC_URL

# Show wallet address
address:
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make env' first."; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
		solana address --keypair $$PRIVATE_KEY_PATH

# All-in-one: setup, build, and show help
install: setup build
	@echo ""
	@echo "✅ Installation complete! Run 'make help' to see available commands."

# Quick start guide
quickstart:
	@if [ -f spec/QUICKSTART.md ]; then \
		cat spec/QUICKSTART.md; \
	else \
		echo "❌ spec/QUICKSTART.md not found"; \
	fi

