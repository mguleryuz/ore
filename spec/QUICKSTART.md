# ORE Mining - Quick Start Guide

This guide will help you set up and run the ORE mining block selection scripts.

## 📋 Prerequisites

- A Solana wallet keypair
- SOL in your wallet for deployments
- Internet connection

## 🚀 Quick Start (3 Steps)

### Step 1: Run Setup Script

First, run the setup script to install all dependencies:

```bash
make setup
# or
./script/setup.sh
```

This script will automatically:
- ✅ Detect your operating system (macOS or Linux)
- ✅ Install Rust and Cargo (if not present)
- ✅ Install Solana CLI tools (if not present)
- ✅ Install required utilities (bc, pkg-config, openssl)
- ✅ Build the project
- ✅ Create `.env` file from `.env.example`
- ✅ Verify your Solana wallet

### Step 2: Configure Your Environment

Edit the `.env` file with your actual configuration:

```bash
nano .env  # or use your preferred editor
```

Update these values:

```bash
# Your Solana wallet keypair path
PRIVATE_KEY_PATH=./tmp/keypair.json

# RPC endpoint (mainnet, devnet, or custom)
RPC_URL=https://api.mainnet-beta.solana.com

# Amount to bet per block in SOL
BET_AMOUNT=0.01

# Number of blocks to randomly select and deploy to (1-25)
BLOCKS_QUANTITY=3

# Optional: delay between deployments (in seconds)
DEPLOYMENT_DELAY=1

# Optional: threshold for "available" blocks (in SOL)
# THRESHOLD_SOL=1.0
```

### Step 3: Run Block Selection Script

Once configured, run the deployment script:

```bash
make deploy
# or
./script/auto_deploy.sh
```

The script will:
- ✅ Validate your configuration
- ✅ Fetch available blocks from mainnet
- ✅ Randomly select N blocks from available ones
- ✅ Show deployment plan and ask for confirmation
- ✅ Convert SOL amounts to lamports automatically
- ✅ Deploy to each selected block
- ✅ Show progress and results
- ✅ Provide a deployment summary

## 📝 Configuration Details

### Block/Square Numbers

The board has 25 squares numbered 0-24 (5x5 grid):

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

### Example Configurations

**Deploy to 3 random available blocks:**
```bash
BLOCKS_QUANTITY=3
BET_AMOUNT=0.01
```

**Deploy to 10 random available blocks:**
```bash
BLOCKS_QUANTITY=10
BET_AMOUNT=0.05
```

**Deploy to a single random block:**
```bash
BLOCKS_QUANTITY=1
BET_AMOUNT=0.1
```

**Deploy to all available blocks:**
```bash
BLOCKS_QUANTITY=25
BET_AMOUNT=0.01
```

**Note:** The script automatically fetches available blocks from mainnet (blocks with deployment < THRESHOLD_SOL) and randomly selects the specified quantity.

## 🔧 Troubleshooting

### Dependencies Not Found

If you get dependency errors, run:
```bash
make setup
# or
./script/setup.sh
```

### RPC Connection Issues

- Try a different RPC endpoint
- Check your internet connection
- Ensure the RPC URL in `.env` is correct

### Wallet Issues

Generate a new Solana wallet if needed:
```bash
make generate-keypair
# or
solana-keygen new
```

### Permission Denied

Make sure scripts are executable:
```bash
chmod +x script/setup.sh script/auto_deploy.sh
```

### Build Failures

Clean and rebuild:
```bash
cargo clean
cargo build --release
```

## 🛠️ Advanced Usage

### Custom RPC Endpoints

For better performance, consider using a custom RPC provider:

```bash
# Example with QuickNode
RPC_URL=https://your-endpoint.solana-mainnet.quiknode.pro/

# Example with Alchemy
RPC_URL=https://solana-mainnet.g.alchemy.com/v2/your-api-key
```

### Different Networks

**Devnet (for testing):**
```bash
RPC_URL=https://api.devnet.solana.com
```

**Mainnet:**
```bash
RPC_URL=https://api.mainnet-beta.solana.com
```

### Multiple Deployments

Run the script multiple times with different block configurations by editing `.env` between runs.

## 📊 Understanding Output

The deployment script provides detailed output:

```
╔════════════════════════════════════════════════════════════╗
║       ORE Mining - Auto Block Selection & Deployment      ║
╚════════════════════════════════════════════════════════════╝

Configuration:
  RPC URL: https://api.mainnet-beta.solana.com
  Keypair: ./tmp/keypair.json
  Bet Amount: 0.01 SOL (10000000 lamports)
  Blocks to select: 3

🔨 Building project...
✅ Build complete

📥 Fetching available blocks from mainnet...
✅ Found 15 available blocks: 0 2 5 8 10 12 14 16 18 19 20 21 22 23 24

🎲 Randomly selecting 3 blocks...
✅ Selected blocks: 5 12 20

╔════════════════════════════════════════════════════════════╗
║                    Deployment Plan                         ║
╚════════════════════════════════════════════════════════════╝
  Total blocks: 3
  Blocks: 5 12 20
  Amount per block: 0.01 SOL
  Total deployment: 0.03 SOL

Continue with deployment? (y/N) y

🚀 Deploying to selected blocks...

📦 Deploying to block #5 (0.01 SOL)...
✅ Successfully deployed to block #5
   Signature: 5Xj...abc

📦 Deploying to block #12 (0.01 SOL)...
✅ Successfully deployed to block #12
   Signature: 3Yk...def

📦 Deploying to block #20 (0.01 SOL)...
✅ Successfully deployed to block #20
   Signature: 2Mn...ghi

╔════════════════════════════════════════════════════════════╗
║                    Deployment Summary                      ║
╚════════════════════════════════════════════════════════════╝

  Blocks selected: 3
  Successfully deployed: 3
  Failed deployments: 0
  Total SOL deployed: 0.03 SOL

✅ All deployments completed successfully!
```

## 📚 Additional Resources

- [Solana Documentation](https://docs.solana.com/)
- [ORE Protocol README](README.md)
- [Rust Documentation](https://doc.rust-lang.org/)

## ⚠️ Important Notes

- Always test on devnet first before deploying on mainnet
- Ensure you have enough SOL in your wallet for deployments + gas fees
- Keep your private key secure and never commit it to version control
- The `.env` file is in `.gitignore` to protect your credentials

## 🆘 Getting Help

If you encounter issues:

1. Check this guide's troubleshooting section
2. Verify your `.env` configuration
3. Ensure all dependencies are installed via `make setup`
4. Check the main [README.md](../README.md) for more details

---

Good luck with your ORE mining! 🎲⛏️

