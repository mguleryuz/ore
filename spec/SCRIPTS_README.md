# ORE Mining Scripts & Automation

This directory contains automated scripts and tools for ORE mining block deployment.

## 📁 Files Created

| File                         | Purpose                                       |
| ---------------------------- | --------------------------------------------- |
| `script/setup.sh`            | Dependency installation and environment setup |
| `script/auto_deploy.sh`      | Block selection and deployment automation     |
| `script/generate_keypair.sh` | Secure keypair generation (no history)        |
| `.env.example`               | Configuration template                        |
| `Makefile`                   | Easy command shortcuts (recommended)          |
| `spec/QUICKSTART.md`         | Detailed getting started guide                |
| `spec/MAKEFILE_REFERENCE.md` | Complete Makefile command reference           |

## 🚀 Recommended Usage (with Makefile)

### First Time Setup

```bash
# Install everything and setup environment
make setup

# Create and configure .env file
make env
nano .env  # Edit with your actual settings

# Verify everything is ready
make check-deps
```

### Daily Usage

```bash
# Check board state
make board

# Deploy to blocks (configured in .env)
make deploy

# Check your miner stats
make miner

# Claim rewards
make claim
```

### Get Help Anytime

```bash
make help  # Show all available commands
```

## 🔧 Alternative Usage (without Makefile)

If you prefer to use the scripts directly:

### First Time Setup

```bash
# Run setup script
make setup
# or
chmod +x script/setup.sh
./script/setup.sh

# Configure .env
cp .env.example .env
nano .env  # Edit with your settings
```

### Deploy to Blocks

```bash
make deploy
# or
chmod +x script/auto_deploy.sh
./script/auto_deploy.sh
```

## ⚙️ Configuration (.env)

Configure your deployment in the `.env` file:

```bash
# Your Solana wallet keypair
PRIVATE_KEY_PATH=./tmp/keypair.json

# RPC endpoint
RPC_URL=https://api.mainnet-beta.solana.com

# Amount to bet per block (in SOL)
BET_AMOUNT=0.01

# Number of blocks to randomly select and deploy to (1-25)
BLOCKS_QUANTITY=3

# Optional: delay between deployments (in seconds)
DEPLOYMENT_DELAY=1

# Optional: threshold for "available" blocks (in SOL)
# THRESHOLD_SOL=1.0
```

## 📊 Block Layout

The board has 25 squares (0-24) in a 5x5 grid:

```
┌────┬────┬────┬────┬────┐
│ 0  │ 1  │ 2  │ 3  │ 4  │
├────┼────┼────┼────┼────┤
│ 5  │ 6  │ 7  │ 8  │ 9  │
├────┼────┼────┼────┼────┤
│ 10 │ 11 │ 12 │ 13 │ 14 │
├────┼────┼────┼────┼────┤
│ 15 │ 16 │ 17 │ 18 │ 19 │
├────┼────┼────┼────┼────┤
│ 20 │ 21 │ 22 │ 23 │ 24 │
└────┴────┴────┴────┴────┘
```

## 🎯 Common Make Commands

### Setup & Info

- `make help` - Show all commands
- `make setup` - Install dependencies
- `make check-deps` - Verify installation
- `make env` - Create .env file

### Deployment

- `make deploy` - Deploy to blocks
- `make build` - Build the project
- `make clean` - Clean build

### Queries

- `make board` - Show board state
- `make miner` - Show your miner
- `make treasury` - Show treasury
- `make config` - Show config
- `make round ID=X` - Show round X

### Transactions

- `make claim` - Claim rewards
- `make checkpoint` - Checkpoint miner
- `make reset` - Reset board

### Wallet

- `make balance` - Show SOL balance
- `make address` - Show wallet address

## 📖 Documentation

- **`QUICKSTART.md`** - Detailed getting started guide
- **`MAKEFILE_REFERENCE.md`** - Complete Makefile documentation
- **`README.md`** - Main project documentation

## 🔍 Features

### Smart Setup Script (`setup.sh`)

✅ Detects macOS and Linux  
✅ Installs Rust, Cargo, Solana CLI  
✅ Installs required utilities (bc, pkg-config, etc.)  
✅ Builds the project  
✅ Never overwrites existing `.env`  
✅ Safe to run multiple times

### Automated Deployment (`auto_deploy.sh`)

✅ Fetches available blocks from mainnet  
✅ Randomly selects N blocks from available ones  
✅ Shows deployment plan with confirmation  
✅ Validates configuration  
✅ Converts SOL to lamports automatically  
✅ Deploys to selected blocks  
✅ Shows deployment progress and signatures  
✅ Provides detailed summary

### Powerful Makefile

✅ 30+ convenient commands  
✅ All phony targets  
✅ Consistent interface  
✅ Parameter passing support  
✅ Color-coded help output  
✅ Error handling

## 🛡️ Safety Features

1. **Configuration Protection**

   - `.env` in `.gitignore`
   - Never overwrites existing config
   - Validates required parameters

2. **Dependency Validation**

   - Checks before running
   - Auto-installs if missing
   - Clear error messages

3. **Build Optimization**
   - Skips rebuild if not needed
   - Parallel compilation support
   - Clean build artifacts easily

## 🔄 Workflow Examples

### Example 1: Quick Deploy

```bash
make deploy
```

### Example 2: Check Everything First

```bash
make board      # See board state
make miner      # Check your stats
make balance    # Check SOL balance
make deploy     # Deploy
```

### Example 3: Monitor Round

```bash
# Get current round from board
make board

# Check specific round details
make round ID=123

# Deploy to that round
make deploy
```

### Example 4: Claim and Re-deploy

```bash
make claim      # Claim rewards
make balance    # Verify SOL received
make deploy     # Deploy again
```

## 🆘 Troubleshooting

### Dependencies Missing

```bash
make setup
# or
./script/setup.sh
```

### .env Not Found

```bash
make env
nano .env  # Configure
```

### Build Errors

```bash
make clean
make build
```

### Permission Errors

```bash
chmod +x script/setup.sh script/auto_deploy.sh
```

## 📊 Environment Variables

You can override `.env` values:

```bash
# Deploy to more blocks temporarily
BLOCKS_QUANTITY=10 make deploy

# Use different amount
BET_AMOUNT=0.05 make deploy

# Use different threshold
THRESHOLD_SOL=0.5 make deploy

# Use different RPC
RPC_URL=https://custom-rpc.com make board
```

## 🎓 Tips

1. **Use `make help`** to see all commands anytime
2. **Run `make check-deps`** to verify setup
3. **Use `make -s`** for silent output
4. **Chain commands** with `&&`: `make build && make deploy`
5. **Tab completion** works with make (in most shells)

## 🔗 Related Commands

```bash
# Solana commands (if you need them)
solana balance --keypair ~/.config/solana/id.json
solana address --keypair ~/.config/solana/id.json
solana-keygen new  # Generate new wallet

# Cargo commands
cargo build --release
cargo test-sbf
cargo clean
```

## 📝 Notes

- Always test on devnet first
- Keep your private key secure
- Monitor gas prices and RPC limits
- Check board state before deploying
- Claim rewards regularly

---

**Need help?** Run `make help` or check `QUICKSTART.md`

Happy mining! ⛏️✨
