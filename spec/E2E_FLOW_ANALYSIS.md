# End-to-End Flow Analysis: auto_deploy.sh → deploy

> **Note**: This document describes the technical flow of the deploy instruction. The deployment script has been updated to automatically fetch and randomly select available blocks. See [QUICKSTART.md](QUICKSTART.md) for current usage.

## Technical Flow (Deploy Instruction)

```
auto_deploy.sh
  ↓
  Load .env config (BLOCKS_QUANTITY, BET_AMOUNT, etc.)
  ↓
  Fetch available blocks from mainnet
  ↓
  Randomly select BLOCKS_QUANTITY blocks
  ↓
  Show plan & confirm with user
  ↓
  For each selected BLOCK:
    - Set SQUARE=$block
    - Set AMOUNT=$BET_LAMPORTS (converted from SOL)
    - Run: cargo run --release --bin ore-cli (COMMAND="deploy")
      ↓
      cli/src/main.rs → deploy()
        ↓
        1. Parse AMOUNT (u64, lamports)
        2. Parse SQUARE (block number 0-24)
        3. Get board → round_id
        4. Create instruction with:
           - signer: payer.pubkey()
           - authority: payer.pubkey()
           - amount: BET_LAMPORTS
           - round_id: board.round_id
           - squares: [bool; 25] bitmask
        5. Submit transaction
        6. Display signature
```

## Issues Found

### 1. ❌ Address Usage - BOTH Signer and Authority Are the Same

**Current Code** (cli/src/main.rs:252-272):

```rust
let ix = ore_api::sdk::deploy(
    payer.pubkey(),          // signer (transaction payer)
    payer.pubkey(),          // authority (miner authority)
    amount,
    board.round_id,
    squares,
);
```

**Expected Function Signature** (api/src/sdk.rs:125-131):

```rust
pub fn deploy(
    signer: Pubkey,          // Must sign the transaction
    authority: Pubkey,       // Authority that owns the miner account
    amount: u64,
    round_id: u64,
    squares: [bool; 25],
) -> Instruction
```

**Status**: ✅ **VALID** (payer is the miner owner, both same is correct)

---

### 2. ✅ BLOCK VALIDATION - Now Checks Available Blocks

**Current**: Script now fetches available blocks before deployment:

- ✅ Queries mainnet round state
- ✅ Filters blocks with deployment < THRESHOLD_SOL
- ✅ Only selects from available blocks
- ✅ Shows user which blocks will be used

**Round State Checks**:

- `deployed: [u64; 25]` - Amount per square
- `count: [u64; 25]` - Miner count per square
- `expires_at: u64` - Round end slot

**Status**: ✅ Implemented

---

### 3. ✅ DEPLOYMENT LOGGING - Comprehensive Tracking

**Implemented**:

- ✅ Transaction signatures for each deployment
- ✅ Which squares succeeded/failed
- ✅ Total SOL deployed summary
- ✅ Per-square status and progress
- ✅ Deployment plan confirmation
- ✅ Final summary report

---

### 4. ✅ AMOUNT CONVERSION - Correct

**Status**: ✅ Valid (1 SOL = 1,000,000,000 lamports)

---

### 5. ✅ FUNCTION ENCODING - Correct Bitmasking

**Process**:

```rust
// 25 bools → 32-bit mask (each bit = 1 square)
let mut mask: u32 = 0;
for (i, &square) in squares.iter().enumerate() {
    if square {
        mask |= 1 << i;
    }
}
// Encode as little-endian [u8; 4]
```

**Status**: ✅ Valid

---

## Summary: E2E Production Ready

### ✅ Core Mechanics Work

- Address usage: Correct
- Amount conversion: Correct
- Function encoding: Correct
- Transaction submission: Correct

### ✅ Production Features Implemented

1. ✅ Pre-flight block availability checks
2. ✅ Round state queries
3. ✅ Deployment result tracking
4. ✅ User confirmation before deployment
5. ✅ Comprehensive error handling
6. ✅ Summary reporting
7. ✅ Transaction signature display
8. ✅ Random block selection

---

## Current Implementation Status

### ✅ Completed Improvements

The `auto_deploy.sh` script now includes:

```bash
# Pre-flight checks ✅
echo "📥 Fetching available blocks from mainnet..."
AVAILABLE_BLOCKS=$(cargo run --release --bin ore-cli)

# Random selection ✅
echo "🎲 Randomly selecting $BLOCKS_QUANTITY blocks..."

# User confirmation ✅
echo "Continue with deployment? (y/N)"

# Track results ✅
DEPLOYED_COUNT=0
FAILED_COUNT=0

# Signature display ✅
SIG=$(echo "$OUTPUT" | grep -E "^[A-Za-z0-9]{87,88}$")
echo "   Signature: $SIG"

# Comprehensive summary ✅
echo "  Successfully deployed: $DEPLOYED_COUNT"
echo "  Total SOL deployed: $(bc calculation)"
```

### Future Enhancements

1. Post-deployment verification (query round state)
2. Retry failed deployments
3. Configurable deployment strategies
4. Performance metrics

---

**Conclusion**: Core flow is production-ready with all essential features implemented. The mechanics are correct, visibility is comprehensive, and user experience is excellent. ✅
