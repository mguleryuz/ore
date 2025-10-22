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

if [ -z "$BLOCKS_QUANTITY" ]; then
    echo "Error: BLOCKS_QUANTITY not set in .env"
    exit 1
fi

# Export variables for the CLI
export KEYPAIR=$PRIVATE_KEY_PATH
export RPC=$RPC_URL

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
echo "║       ORE Mining - Auto Block Selection & Deployment      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  RPC URL: $RPC_URL"
echo "  Keypair: $PRIVATE_KEY_PATH"
echo "  Bet Amount: $BET_AMOUNT SOL ($BET_LAMPORTS lamports)"
echo "  Blocks to select: $BLOCKS_QUANTITY"
echo ""

# Build the project first
echo "🔨 Building project..."
cd "$(dirname "$0")/.."
cargo build --release --bin ore-cli 2>&1 | grep -v "warning:" | grep -E "(Compiling|Finished|error:)" || true

if [ $? -ne 0 ]; then
    echo "Error: Build failed"
    exit 1
fi

echo "✅ Build complete"
echo ""

# Fetch available blocks from mainnet
echo "📥 Fetching available blocks from mainnet..."
export COMMAND="available_blocks"
export THRESHOLD_SOL=${THRESHOLD_SOL:-1.0}

AVAILABLE_BLOCKS=$(cargo run --release --bin ore-cli 2>/dev/null)

if [ -z "$AVAILABLE_BLOCKS" ]; then
    echo "❌ Failed to fetch available blocks or no blocks available"
    echo "   Try increasing THRESHOLD_SOL or check your RPC connection"
    exit 1
fi

# Convert space-separated string to array
read -ra AVAILABLE_ARRAY <<< "$AVAILABLE_BLOCKS"

echo "✅ Found ${#AVAILABLE_ARRAY[@]} available blocks: ${AVAILABLE_BLOCKS}"
echo ""

# Validate BLOCKS_QUANTITY
if [ "$BLOCKS_QUANTITY" -gt "${#AVAILABLE_ARRAY[@]}" ]; then
    echo "⚠️  Warning: Requested $BLOCKS_QUANTITY blocks but only ${#AVAILABLE_ARRAY[@]} available"
    echo "   Deploying to all ${#AVAILABLE_ARRAY[@]} available blocks"
    BLOCKS_QUANTITY=${#AVAILABLE_ARRAY[@]}
fi

if [ "$BLOCKS_QUANTITY" -le 0 ]; then
    echo "❌ BLOCKS_QUANTITY must be greater than 0"
    exit 1
fi

# Randomly select N blocks from available blocks
echo "🎲 Randomly selecting $BLOCKS_QUANTITY blocks..."

# Use a cross-platform method to shuffle (works on macOS and Linux)
SELECTED_BLOCKS=()
# Create array of indices and shuffle them
INDICES=()
for ((i=0; i<${#AVAILABLE_ARRAY[@]}; i++)); do
    INDICES+=($i)
done

# Simple shuffle algorithm (Fisher-Yates)
for ((i=${#INDICES[@]}-1; i>0; i--)); do
    j=$((RANDOM % (i+1)))
    # Swap
    temp=${INDICES[i]}
    INDICES[i]=${INDICES[j]}
    INDICES[j]=$temp
done

# Select first N indices
for ((i=0; i<$BLOCKS_QUANTITY && i<${#INDICES[@]}; i++)); do
    idx=${INDICES[i]}
    SELECTED_BLOCKS+=("${AVAILABLE_ARRAY[$idx]}")
done

# Sort selected blocks for nicer display
IFS=$'\n' SELECTED_BLOCKS=($(sort -n <<<"${SELECTED_BLOCKS[*]}"))
unset IFS

echo "✅ Selected blocks: ${SELECTED_BLOCKS[*]}"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Deployment Plan                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "  Total blocks: $BLOCKS_QUANTITY"
echo "  Blocks: ${SELECTED_BLOCKS[*]}"
echo "  Amount per block: $BET_AMOUNT SOL"
echo "  Total deployment: $(echo "$BET_AMOUNT * $BLOCKS_QUANTITY" | bc) SOL"
echo ""
read -p "Continue with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

echo ""
echo "🚀 Deploying to selected blocks..."
echo ""

# Deploy to each selected block
DEPLOYED_COUNT=0
FAILED_COUNT=0
export COMMAND="deploy"

for block in "${SELECTED_BLOCKS[@]}"; do
    export SQUARE=$block
    
    echo "📦 Deploying to block #$block ($BET_AMOUNT SOL)..."
    
    # Run the deployment
    OUTPUT=$(cargo run --release --bin ore-cli 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Successfully deployed to block #$block"
        # Extract transaction signature if available
        SIG=$(echo "$OUTPUT" | grep -E "^[A-Za-z0-9]{87,88}$" | head -1)
        if [ ! -z "$SIG" ]; then
            echo "   Signature: $SIG"
        fi
        ((DEPLOYED_COUNT++))
    else
        echo "❌ Failed to deploy to block #$block"
        # Show detailed error messages (filter out compile/build messages)
        echo "$OUTPUT" | grep -v "Compiling\|Finished\|warning:" | grep -E "(❌|Error|error|Insufficient|balance|needed|Deposit)" || echo "$OUTPUT"
        ((FAILED_COUNT++))
    fi
    
    echo ""
    
    # Add delay between deployments to avoid rate limiting
    # Get last block in array using array length
    LAST_BLOCK="${SELECTED_BLOCKS[$((${#SELECTED_BLOCKS[@]} - 1))]}"
    
    if [ ! -z "$DEPLOYMENT_DELAY" ] && [ $DEPLOYMENT_DELAY -gt 0 ] && [ "$block" != "$LAST_BLOCK" ]; then
        echo "⏳ Waiting ${DEPLOYMENT_DELAY}s before next deployment..."
        sleep $DEPLOYMENT_DELAY
        echo ""
    fi
done

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Deployment Summary                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Blocks selected: $BLOCKS_QUANTITY"
echo "  Successfully deployed: $DEPLOYED_COUNT"
echo "  Failed deployments: $FAILED_COUNT"
echo "  Total SOL deployed: $(echo "$BET_AMOUNT * $DEPLOYED_COUNT" | bc) SOL"
echo ""

if [ $DEPLOYED_COUNT -eq $BLOCKS_QUANTITY ]; then
    echo "✅ All deployments completed successfully!"
    exit 0
elif [ $DEPLOYED_COUNT -gt 0 ]; then
    echo "⚠️  Some deployments completed with errors"
    exit 1
else
    echo "❌ All deployments failed"
    exit 1
fi
