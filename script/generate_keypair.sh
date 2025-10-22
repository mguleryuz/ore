#!/bin/bash

# Secure Solana Keypair Generator (Automated)
# This script generates a Solana keypair without saving commands to shell history
# Runs non-interactively and stores keypair in ./tmp/keypair.json

set -e

# Disable history for this session (prevents zsh/bash from recording)
unset HISTFILE

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default keypair path (project local)
KEYPAIR_PATH="${PROJECT_ROOT}/tmp/keypair.json"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}        Secure Solana Keypair Generator                    ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if solana-keygen is installed
if ! command -v solana-keygen &> /dev/null; then
    echo -e "${RED}❌ Error: solana-keygen not found${NC}"
    echo ""
    echo "Solana CLI is required but not installed."
    echo ""
    echo "Please run setup first to install all dependencies:"
    echo "  make setup"
    echo ""
    echo "Or install Solana CLI manually:"
    echo "  sh -c \"\$(curl -sSfL https://release.solana.com/stable/install)\""
    exit 1
fi

# Create tmp directory if it doesn't exist
mkdir -p "$(dirname "$KEYPAIR_PATH")"

echo -e "${BLUE}📝 Keypair location: ${KEYPAIR_PATH}${NC}"
echo ""

# Check if file already exists
if [ -f "$KEYPAIR_PATH" ]; then
    echo -e "${YELLOW}⚠️  Keypair already exists at: ${KEYPAIR_PATH}${NC}"
    echo -e "${BLUE}Using existing keypair.${NC}"
    echo ""
else
    echo -e "${BLUE}🔐 Generating new keypair...${NC}"
    echo ""

    # Generate keypair (non-interactive, force overwrite, no passphrase)
    solana-keygen new --outfile "$KEYPAIR_PATH" --no-bip39-passphrase --force 2>&1 | grep -v "wrote" || true

    echo ""
    echo -e "${GREEN}✅ Keypair generated successfully!${NC}"
    echo ""
fi

# Display public key
PUBKEY=$(solana-keygen pubkey "$KEYPAIR_PATH" 2>/dev/null)
echo -e "${GREEN}🔑 Public Key: ${PUBKEY}${NC}"
echo ""

# Security warnings
echo -e "${YELLOW}⚠️  SECURITY WARNINGS:${NC}"
echo -e "${RED}1. NEVER share your private key (the JSON file)${NC}"
echo -e "${RED}2. NEVER commit this file to git (.gitignore has tmp/)${NC}"
echo -e "${RED}3. Keep secure backups in a safe location${NC}"
echo -e "${RED}4. This command was NOT saved to shell history${NC}"
echo ""

# Check if .env exists and update it
ENV_FILE="${PROJECT_ROOT}/.env"
if [ -f "$ENV_FILE" ]; then
    # Check if PRIVATE_KEY_PATH already exists
    if grep -q "^PRIVATE_KEY_PATH=" "$ENV_FILE"; then
        # Update existing line
        sed -i.bak "s|^PRIVATE_KEY_PATH=.*|PRIVATE_KEY_PATH=${KEYPAIR_PATH}|" "$ENV_FILE"
        rm "${ENV_FILE}.bak" 2>/dev/null || true
        echo -e "${GREEN}✅ Updated PRIVATE_KEY_PATH in .env${NC}"
    else
        # Add new line
        echo "PRIVATE_KEY_PATH=${KEYPAIR_PATH}" >> "$ENV_FILE"
        echo -e "${GREEN}✅ Added PRIVATE_KEY_PATH to .env${NC}"
    fi
    echo ""
fi

echo -e "${BLUE}💰 Quick Commands:${NC}"
echo "  Check balance:"
echo "    solana balance --keypair ${KEYPAIR_PATH}"
echo ""
echo "  Request airdrop (devnet):"
echo "    solana airdrop 1 --keypair ${KEYPAIR_PATH} --url devnet"
echo ""
echo "  Show address:"
echo "    solana address --keypair ${KEYPAIR_PATH}"
echo ""

# Re-enable history for next commands
export HISTFILE="$HOME/.zsh_history"

