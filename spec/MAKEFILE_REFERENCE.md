# Makefile Quick Reference

This document provides a comprehensive guide to all available `make` commands for the ORE mining project.

## 🚀 Quick Start

```bash
# First time setup
make install        # or make setup

# Configure your environment
make env            # Create .env file
nano .env           # Edit with your settings

# Deploy to blocks
make deploy         # Run block selection script
```

## 📋 All Available Commands

### Setup & Configuration

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands (default) |
| `make setup` | Install all dependencies and setup environment |
| `make env` | Create `.env` file from `.env.example` |
| `make check-deps` | Check if all dependencies are installed |
| `make install` | Complete installation (setup + build) |

### Building & Testing

| Command | Description |
|---------|-------------|
| `make build` | Build the project in release mode |
| `make build-debug` | Build the project in debug mode |
| `make clean` | Clean build artifacts |
| `make test` | Run Solana BPF tests |
| `make fmt` | Format code with rustfmt |
| `make fmt-check` | Check code formatting |
| `make lint` | Run clippy linter |
| `make update` | Update dependencies |

### Deployment

| Command | Description |
|---------|-------------|
| `make deploy` | Auto-deploy to randomly selected available blocks |

### Query Commands

| Command | Description | Example |
|---------|-------------|---------|
| `make board` | Show current board state | `make board` |
| `make miner` | Show your miner information | `make miner` |
| `make treasury` | Show treasury information | `make treasury` |
| `make config` | Show config information | `make config` |
| `make clock` | Show current clock/slot info | `make clock` |
| `make stake` | Show stake information | `make stake` |
| `make round` | Show specific round info | `make round ID=123` |

### Transaction Commands

| Command | Description | Example |
|---------|-------------|---------|
| `make claim` | Claim mining rewards (SOL + ORE) | `make claim` |
| `make checkpoint` | Checkpoint a miner | `make checkpoint AUTHORITY=<pubkey>` |
| `make checkpoint-all` | Checkpoint all miners | `make checkpoint-all` |
| `make reset` | Reset the board for a new round | `make reset` |

### Wallet Commands

| Command | Description |
|---------|-------------|
| `make balance` | Show wallet balance |
| `make address` | Show wallet address |

### Utilities

| Command | Description |
|---------|-------------|
| `make install-solana` | Install Solana CLI only |
| `make install-rust` | Install Rust only |
| `make quickstart` | Display the quick start guide |

## 📝 Detailed Examples

### Example 1: Complete First-Time Setup

```bash
# 1. Install everything
make install

# 2. Create and configure .env
make env
nano .env  # Edit your settings

# 3. Check everything is ready
make check-deps

# 4. View current board
make board

# 5. Deploy to blocks
make deploy
```

### Example 2: Query Blockchain State

```bash
# Check board status
make board

# Check your miner stats
make miner

# Check treasury
make treasury

# Check specific round
make round ID=42

# Check your wallet
make balance
make address
```

### Example 3: Mining Operations

```bash
# Deploy to blocks (configured in .env)
make deploy

# Claim your rewards
make claim

# Check your updated stats
make miner
```

### Example 4: Development Workflow

```bash
# Make code changes...

# Format code
make fmt

# Run linter
make lint

# Run tests
make test

# Build release
make build
```

### Example 5: Checkpoint Operations

```bash
# Checkpoint your own miner
make checkpoint

# Checkpoint specific miner
make checkpoint AUTHORITY=YourSolanaAddress...

# Checkpoint all miners
make checkpoint-all
```

## 🎯 Common Workflows

### Daily Mining Routine

```bash
# 1. Check board state
make board

# 2. Deploy to selected blocks
make deploy

# 3. Check your miner status
make miner

# 4. Claim rewards when ready
make claim
```

### Monitoring Workflow

```bash
# Quick status check
make board && make miner && make treasury

# Check specific round details
make round ID=123

# Monitor wallet
make balance
```

### Development Workflow

```bash
# Before committing code
make fmt
make lint
make test
make build
```

## ⚙️ Configuration

All commands that interact with the blockchain use the `.env` file for configuration:

```bash
PRIVATE_KEY_PATH=./tmp/keypair.json
RPC_URL=https://api.mainnet-beta.solana.com
BET_AMOUNT=0.01
BLOCKS_QUANTITY=3
DEPLOYMENT_DELAY=1
```

## 🔍 Troubleshooting

### "make: command not found"

Make is not installed. Install it:

**macOS:**
```bash
xcode-select --install
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install build-essential
```

**Linux (Fedora):**
```bash
sudo dnf install make
```

### ".env file not found"

Create the `.env` file:
```bash
make env
nano .env  # Edit with your settings
```

### "Dependencies not installed"

Run setup:
```bash
make setup
```

### Build errors

Clean and rebuild:
```bash
make clean
make build
```

## 📚 Additional Resources

- Run `make help` anytime to see all commands
- Check `QUICKSTART.md` for detailed getting started guide
- See `README.md` for project documentation

## 💡 Tips

1. **Tab Completion**: Type `make ` and press TAB to see available commands (if your shell supports it)

2. **Combine Commands**: You can chain commands with `&&`:
   ```bash
   make build && make deploy
   ```

3. **Environment Variables**: Override `.env` values temporarily:
   ```bash
   BLOCKS_QUANTITY=10 make deploy
   BET_AMOUNT=0.05 make deploy
   ```

4. **Silent Mode**: Add `-s` flag to suppress make output:
   ```bash
   make -s board
   ```

5. **Parallel Builds**: Speed up compilation with parallel jobs:
   ```bash
   make build -j4
   ```

## 🎓 Learning More About Make

- [GNU Make Manual](https://www.gnu.org/software/make/manual/)
- [Make Tutorial](https://makefiletutorial.com/)

---

Happy mining! ⛏️✨

