# End-to-End Flow Analysis: select_blocks.sh → deploy

## Current Flow

```
select_blocks.sh
  ↓
  Load .env config
  ↓
  For each BLOCK in BLOCKS:
    - Set SQUARE=$block
    - Set AMOUNT=$BET_LAMPORTS
    - Run: cargo run --release --bin ore-cli (COMMAND="deploy")
      ↓
      cli/src/main.rs → deploy()
        ↓
        1. Parse AMOUNT (u64, lamports)
        2. Parse SQUARE (block number 0-24)
        3. Get board → round_id
        4. Create instruction with:
           - signer: payer.pubkey()
           - authority: payer.pubkey()  ⚠️ BOTH THE SAME
           - amount: BET_LAMPORTS
           - round_id: board.round_id
           - squares: [bool; 25] bitmask
        5. Submit transaction
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

### 2. ❌ NO VALIDATION - Not Checking Available Blocks

**Current**: Script deploys to whatever blocks are in .env without checking:

- ❌ Is the block already taken?
- ❌ Is the round still active?

**Required Checks**: Round state has:

- `deployed: [u64; 25]` - Amount per square
- `count: [u64; 25]` - Miner count per square
- `expires_at: u64` - Round end slot

**Solution**: Query round state before deploying

---

### 3. ❌ MISSING LOGGING - No Deployment Tracking

**Missing**:

- Transaction signatures for each deployment
- Which squares succeeded/failed
- Total SOL deployed summary
- Per-square status

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

## Summary: E2E Solid?

### ✅ Core Mechanics Work

- Address usage: Correct
- Amount conversion: Correct
- Function encoding: Correct
- Transaction submission: Correct

### ❌ Missing Production Features

1. Pre-flight block availability checks
2. Round state queries
3. Deployment result tracking
4. Post-deployment verification
5. Comprehensive error handling
6. Summary reporting

---

## Recommendations

### Immediate Improvements

Add to `select_blocks.sh`:

```bash
# Pre-flight checks
echo "Querying available blocks..."
make board  # Show current state
make round ID=$(get_round_id)  # Show round details

# Track results
DEPLOYMENT_RESULTS=()
DEPLOYMENT_SIGS=()

# After deployments
echo "Verifying deployments..."
make round ID=$(get_round_id)  # Confirm blocks updated
```

### Priority Order

1. Add `make board` call before deployment
2. Track and log transaction signatures
3. Add post-deployment verification
4. Display per-square deployment status
5. Add error categorization

---

**Conclusion**: Core flow is solid for basic deployment, but needs visibility improvements for production use. The mechanics are correct, the visibility is missing. 🔍
