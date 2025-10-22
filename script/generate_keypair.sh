#!/bin/bash

# Secure Solana Keypair Generator (Automated)
# This script generates a Solana keypair without saving commands to shell history
# Runs non-interactively and stores keypair in ./tmp/keypair.json
#
# Usage:
#   ./script/generate_keypair.sh                                    # Generate new random keypair
#   ./script/generate_keypair.sh "seed phrase words..."             # Import from BIP39 seedphrase (account 0)
#   ./script/generate_keypair.sh "seed phrase words..." 1           # Import from BIP39 seedphrase (account 1)
#   ./script/generate_keypair.sh "base58_private_key"               # Import from base58 private key
#   ./script/generate_keypair.sh "[1,2,3,...]"                      # Import from JSON byte array
#
# Derivation Path:
#   Uses Solana standard: m/44'/501'/account'/0'
#   This matches web3.js derivePath behavior

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

# Get optional input argument (seedphrase or private key)
INPUT="${1:-}"

# Get optional account number (for BIP39 derivation path: m/44'/501'/account'/0')
# Default to 0, matches the TypeScript: m/44'/501'/${accountNumber}'/0'
ACCOUNT_NUMBER="${2:-0}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}        Secure Solana Keypair Generator                    ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📝 Keypair location: ${KEYPAIR_PATH}${NC}"
echo ""

# Create tmp directory if it doesn't exist
mkdir -p "$(dirname "$KEYPAIR_PATH")"

# Function to detect input type
detect_input_type() {
    local input="$1"
    
    # Check if empty
    if [ -z "$input" ]; then
        echo "none"
        return
    fi
    
    # Check if it's a JSON byte array: starts with [ and ends with ]
    if [[ "$input" =~ ^\[.*\]$ ]]; then
        echo "json_array"
        return
    fi
    
    # Check if it's a base58 private key (typically 87-88 characters, alphanumeric)
    # Solana private keys in base58 are usually 87-88 chars
    if [[ "$input" =~ ^[1-9A-HJ-NP-Za-km-z]{87,88}$ ]]; then
        echo "base58"
        return
    fi
    
    # Check if it looks like a seedphrase (multiple words separated by spaces)
    # BIP39 seedphrases are typically 12 or 24 words
    word_count=$(echo "$input" | wc -w | tr -d ' ')
    if [ "$word_count" -eq 12 ] || [ "$word_count" -eq 24 ]; then
        echo "seedphrase"
        return
    fi
    
    # If it has spaces and multiple words but not 12/24, still try as seedphrase
    if [[ "$input" =~ [[:space:]] ]] && [ "$word_count" -gt 1 ]; then
        echo "seedphrase"
        return
    fi
    
    # Default to unknown
    echo "unknown"
}

# Detect input type
INPUT_TYPE=$(detect_input_type "$INPUT")

case "$INPUT_TYPE" in
    none)
        echo -e "${BLUE}🔐 Generating new random keypair...${NC}"
        echo ""
        
        # Generate keypair (non-interactive, force overwrite, no passphrase)
        solana-keygen new --outfile "$KEYPAIR_PATH" --no-bip39-passphrase --force 2>&1 | grep -v "wrote" || true
        
        echo ""
        echo -e "${GREEN}✅ Keypair generated successfully!${NC}"
        ;;
        
    seedphrase)
        echo -e "${BLUE}🔐 Importing keypair from BIP39 seedphrase...${NC}"
        echo -e "${YELLOW}   Detected: Seedphrase ($(echo "$INPUT" | wc -w | tr -d ' ') words)${NC}"
        echo -e "${YELLOW}   Account: $ACCOUNT_NUMBER${NC}"
        echo ""
        
        # Import from seedphrase using proper Solana derivation path: m/44'/501'/account'/0'
        # This matches the TypeScript derivation: derivePath("m/44'/501'/${accountNumber}'/0'", seed)
        echo "$INPUT" | solana-keygen recover --outfile "$KEYPAIR_PATH" --force --derivation-path "m/44'/501'/$ACCOUNT_NUMBER'/0'" 2>&1 | grep -v "wrote" || true
        
        echo ""
        echo -e "${GREEN}✅ Keypair imported from seedphrase!${NC}"
        ;;
        
    base58)
        echo -e "${BLUE}🔐 Importing keypair from base58 private key...${NC}"
        echo -e "${YELLOW}   Detected: Base58 encoded private key${NC}"
        echo ""
        
        # Import base58 private key (keypair) directly
        # Solana keypairs are 64 bytes (32 secret + 32 public) encoded in base58
        python3 << PYTHON_SCRIPT
import base58
import json
import sys
import subprocess

try:
    key = "$INPUT"
    decoded = base58.b58decode(key)
    
    # Should be 64 bytes (full keypair)
    if len(decoded) != 64:
        print(f"Error: Expected 64 bytes, got {len(decoded)}", file=sys.stderr)
        sys.exit(1)
    
    key_array = list(decoded)
    
    # Write to keypair file
    with open("$KEYPAIR_PATH", 'w') as f:
        json.dump(key_array, f)
    
    # Verify by getting the public key
    try:
        result = subprocess.run(['solana-keygen', 'pubkey', '$KEYPAIR_PATH'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            pubkey = result.stdout.strip()
            print(f"Keypair imported successfully")
            print(f"Public Key: {pubkey}")
        else:
            print(f"Warning: Could not verify keypair", file=sys.stderr)
    except Exception as e:
        print(f"Warning: {e}", file=sys.stderr)
        
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
        
        echo ""
        echo -e "${GREEN}✅ Keypair imported from base58 private key!${NC}"
        ;;
        
    json_array)
        echo -e "${BLUE}🔐 Importing keypair from JSON byte array...${NC}"
        echo -e "${YELLOW}   Detected: JSON array format${NC}"
        echo ""
        
        # Write JSON array directly to file
        echo "$INPUT" > "$KEYPAIR_PATH"
        
        # Verify it's a valid keypair
        if solana-keygen pubkey "$KEYPAIR_PATH" &> /dev/null; then
            echo -e "${GREEN}✅ Keypair imported from JSON array!${NC}"
        else
            echo -e "${RED}❌ Error: Invalid JSON array format${NC}"
            echo "   Expected format: [num1,num2,num3,...] with 64 bytes"
            rm -f "$KEYPAIR_PATH"
            exit 1
        fi
        ;;
        
    unknown)
        echo -e "${RED}❌ Error: Could not detect input type${NC}"
        echo ""
        echo "Supported formats:"
        echo "  • BIP39 Seedphrase: 12 or 24 words separated by spaces"
        echo "  • Base58 Private Key: 87-88 character alphanumeric string"
        echo "  • JSON Byte Array: [1,2,3,...] with 64 bytes"
        echo ""
        echo "Examples:"
        echo "  ./script/generate_keypair.sh \"word1 word2 word3...\""
        echo "  ./script/generate_keypair.sh \"5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn\""
        echo "  ./script/generate_keypair.sh '[1,2,3,4,...]'"
        exit 1
        ;;
esac

# Display public key
if [ -f "$KEYPAIR_PATH" ]; then
    PUBKEY=$(solana-keygen pubkey "$KEYPAIR_PATH" 2>/dev/null)
    echo ""
    echo -e "${GREEN}🔑 Public Key: ${PUBKEY}${NC}"
    echo ""
else
    echo -e "${RED}❌ Error: Keypair file was not created${NC}"
    exit 1
fi

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
