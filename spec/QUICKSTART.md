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
./setup.sh
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
PRIVATE_KEY_PATH=/Users/yourusername/.config/solana/id.json

# RPC endpoint (mainnet, devnet, or custom)
RPC_URL=https://api.mainnet-beta.solana.com

# Amount to bet per block in SOL
BET_AMOUNT=0.1

# Blocks to deploy to (0-24, comma-separated)
BLOCKS=5,10,15,20

# Optional: delay between deployments (in seconds)
DEPLOYMENT_DELAY=1
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

**Single block (center):**
```bash
BLOCKS=12
```

**Corner blocks:**
```bash
BLOCKS=0,4,20,24
```

**All blocks:**
```bash
BLOCKS=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
```

**Strategic selection (cross pattern):**
```bash
BLOCKS=2,10,11,12,13,14,22
```

## 🔧 Troubleshooting

### Dependencies Not Found

If you get dependency errors, run:
```bash
./setup.sh
```

### RPC Connection Issues

- Try a different RPC endpoint
- Check your internet connection
- Ensure the RPC URL in `.env` is correct

### Wallet Issues

Generate a new Solana wallet if needed:
```bash
solana-keygen new
```

### Permission Denied

Make sure scripts are executable:
```bash
chmod +x setup.sh auto_deploy.sh
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
║         ORE Mining - Block Selection & Deployment         ║
╚════════════════════════════════════════════════════════════╝

Configuration:
  RPC URL: https://api.mainnet-beta.solana.com
  Keypair: /Users/you/.config/solana/id.json
  Bet Amount: 0.1 SOL (100000000 lamports)
  Blocks to deploy: 5,10,15

Building project...

Deploying to selected blocks...

📦 Deploying to block #5...
✅ Successfully deployed to block #5

📦 Deploying to block #10...
✅ Successfully deployed to block #10

📦 Deploying to block #15...
✅ Successfully deployed to block #15

╔════════════════════════════════════════════════════════════╗
║                    Deployment Summary                      ║
╚════════════════════════════════════════════════════════════╝

  Total blocks attempted: 3
  Successfully deployed: 3
  Failed deployments: 0

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
3. Ensure all dependencies are installed via `./setup.sh`
4. Check the main [README.md](README.md) for more details

---

Good luck with your ORE mining! 🎲⛏️

