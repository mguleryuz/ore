#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env file not found"
    echo ""
    echo "Please run setup first:"
    echo "  make setup"
    exit 1
fi

# Validate required environment variables
if [ -z "$PRIVATE_KEY_PATH" ]; then
    echo "Error: PRIVATE_KEY_PATH not set in .env"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "Error: RPC_URL not set in .env"
    exit 1
fi

if [ -z "$BET_AMOUNT" ]; then
    echo "Error: BET_AMOUNT not set in .env"
    exit 1
fi

if [ -z "$BLOCKS" ]; then
    echo "Error: BLOCKS not set in .env"
    exit 1
fi

# Export variables for the CLI
export KEYPAIR=$PRIVATE_KEY_PATH
export RPC=$RPC_URL
export COMMAND="deploy"

# Convert BET_AMOUNT from SOL to lamports if needed
# 1 SOL = 1,000,000,000 lamports
if [[ $BET_AMOUNT == *.* ]]; then
    # If decimal, convert to lamports
    BET_LAMPORTS=$(echo "$BET_AMOUNT * 1000000000" | bc | cut -d. -f1)
else
    BET_LAMPORTS=$BET_AMOUNT
fi

export AMOUNT=$BET_LAMPORTS

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         ORE Mining - Block Selection & Deployment         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  RPC URL: $RPC_URL"
echo "  Keypair: $PRIVATE_KEY_PATH"
echo "  Bet Amount: $BET_AMOUNT SOL ($BET_LAMPORTS lamports)"
echo "  Blocks to deploy: $BLOCKS"
echo ""

# Parse blocks (can be comma-separated or space-separated)
IFS=',' read -ra BLOCK_ARRAY <<< "$BLOCKS"

# Build the project first
echo "Building project..."
cd "$(dirname "$0")"
cargo build --release --bin ore-cli 2>&1 | grep -v "warning:"

if [ $? -ne 0 ]; then
    echo "Error: Build failed"
    exit 1
fi

echo ""
echo "Deploying to selected blocks..."
echo ""

# Deploy to each selected block
DEPLOYED_COUNT=0
FAILED_COUNT=0

for block in "${BLOCK_ARRAY[@]}"; do
    # Trim whitespace
    block=$(echo $block | xargs)
    
    # Validate block number (0-24)
    if ! [[ "$block" =~ ^[0-9]+$ ]] || [ "$block" -lt 0 ] || [ "$block" -gt 24 ]; then
        echo "❌ Invalid block number: $block (must be 0-24)"
        ((FAILED_COUNT++))
        continue
    fi
    
    export SQUARE=$block
    
    echo "📦 Deploying to block #$block..."
    
    # Run the deployment
    cargo run --release --bin ore-cli 2>&1 | grep -E "(Transaction|Error)"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ Successfully deployed to block #$block"
        ((DEPLOYED_COUNT++))
    else
        echo "❌ Failed to deploy to block #$block"
        ((FAILED_COUNT++))
    fi
    
    echo ""
    
    # Add delay between deployments to avoid rate limiting
    if [ ! -z "$DEPLOYMENT_DELAY" ] && [ $DEPLOYMENT_DELAY -gt 0 ]; then
        sleep $DEPLOYMENT_DELAY
    fi
done

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Deployment Summary                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Total blocks attempted: ${#BLOCK_ARRAY[@]}"
echo "  Successfully deployed: $DEPLOYED_COUNT"
echo "  Failed deployments: $FAILED_COUNT"
echo ""

if [ $DEPLOYED_COUNT -eq ${#BLOCK_ARRAY[@]} ]; then
    echo "✅ All deployments completed successfully!"
    exit 0
elif [ $DEPLOYED_COUNT -gt 0 ]; then
    echo "⚠️  Some deployments completed with errors"
    exit 1
else
    echo "❌ All deployments failed"
    exit 1
fi

