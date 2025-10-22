# E2E Testing Guide

This document explains the end-to-end (E2E) testing infrastructure for the ORE mining block selection and deployment flow.

## Overview

The E2E test suite validates the complete workflow from querying available blocks through deployment and verification, using mainnet state for realistic testing.

## Architecture

### Test Framework

- **LiteSVM**: Lightweight Solana VM for fast local testing
- **Mainnet Fork**: Fetch real accounts from mainnet RPC
- **Simulation**: Test deployment mechanics without actual transactions

### Test Structure

```
test/
├── Cargo.toml          # Test package configuration
├── src/
│   ├── lib.rs          # Library exports
│   └── helpers.rs      # Helper functions and utilities
└── tests/
    └── deploy_e2e.rs   # E2E test suite
```

## Running Tests

### All E2E Tests

```bash
make test-e2e
# or
cd test && cargo test --release
```

### Verbose Output

```bash
make test-e2e-verbose
# or
cd test && cargo test --release -- --nocapture
```

### Mainnet Query Tests

```bash
make test-e2e-mainnet
# or
cd test && cargo test --release test_query_available_blocks -- --nocapture --ignored
```

### Individual Tests

```bash
cd test
cargo test test_amount_encoding -- --nocapture
cargo test test_block_bitmask_encoding -- --nocapture
cargo test test_deploy_instruction_creation -- --nocapture
```

## Test Scenarios

### 1. Query Available Blocks (`test_query_available_blocks`)

**Purpose**: Validate ability to fetch and parse mainnet board/round state

**Process**:
1. Fetch board account from mainnet
2. Parse board to get current round_id
3. Fetch round account
4. Display all 25 blocks with deployment status
5. Identify available blocks

**Validation**:
- Board and round data structures are valid
- All 25 squares present
- Data matches expected format

**Note**: Requires mainnet RPC access, run with `--ignored` flag

### 2. Full Deployment Flow (`test_full_deployment_flow`)

**Purpose**: Simulate complete deployment process

**Process**:
1. Setup test context with LiteSVM
2. Create test miner account
3. Fund account with SOL
4. (Would) deploy to selected blocks
5. (Would) verify state changes

**Current Status**: Framework in place, needs mainnet fork integration

### 3. Amount Encoding (`test_amount_encoding`)

**Purpose**: Verify SOL to lamports conversion

**Test Cases**:
- 0.1 SOL = 100,000,000 lamports
- 0.5 SOL = 500,000,000 lamports
- 1.0 SOL = 1,000,000,000 lamports
- 5.0 SOL = 5,000,000,000 lamports

**Validation**: All conversions must be exact

### 4. Block Bitmask Encoding (`test_block_bitmask_encoding`)

**Purpose**: Validate block selection encoding

**Test Patterns**:
- Single block (0)
- Corners (0, 24)
- Center (12)
- Cross pattern (0, 6, 12, 18, 24)
- Diagonal (5, 10, 15, 20)

**Process**:
1. Convert block list to boolean array
2. Encode as 32-bit bitmask
3. Decode back to block list
4. Verify round-trip accuracy

### 5. Deploy Instruction Creation (`test_deploy_instruction_creation`)

**Purpose**: Verify correct instruction building

**Validation**:
- Correct program ID
- 7 accounts (signer, authority, automation, board, miner, round, system)
- Non-empty instruction data
- Proper parameter encoding

### 6. PDA Derivation (`test_pda_derivation`)

**Purpose**: Verify Program Derived Addresses

**PDAs Tested**:
- Board PDA (seed: "board")
- Config PDA (seed: "config")
- Treasury PDA (seed: "treasury")
- Miner PDA (seed: "miner" + authority)
- Round PDA (seed: "round" + round_id)

**Validation**: All bumps valid (0-255)

### 7. Transaction Construction (`test_transaction_construction`)

**Purpose**: Verify production-ready transaction building

**Components**:
1. Compute budget limit instruction
2. Compute budget price instruction
3. Deploy instruction

**Validation**: 3 instructions, correct program IDs

## Helper Functions

### Account Management

```rust
// Fetch mainnet account
fetch_mainnet_account(rpc_url, address) -> Account

// Setup test context
setup_test_context() -> LiteSVM

// Fund test account
fund_account(svm, pubkey, lamports)

// Add mainnet account to test
add_mainnet_account(svm, address, account)
```

### Parsing

```rust
// Parse accounts
parse_board(account) -> Board
parse_round(account) -> Round
parse_miner(account) -> Miner
```

### Display

```rust
// Pretty print board state
display_board_state(board, round, slot)

// Display deployment summary
display_deployment_summary(blocks, amount, sigs)
```

### Analysis

```rust
// Get available blocks
get_available_blocks(round, threshold_sol) -> Vec<usize>
```

### Instruction Building

```rust
// Create deploy instruction
create_deploy_instruction(
    signer,
    authority,
    amount_lamports,
    round_id,
    blocks
) -> Instruction
```

### Verification

```rust
// Verify deployment
verify_deployment(old_round, new_round, blocks, amount) -> Result<()>

// Verify miner state
verify_miner_state(miner, blocks, amount, round_id) -> Result<()>
```

## Key Addresses

**Program ID**: `oreV3EG1i9BEgiAJ8b177Z2S2rMarzak4NMv1kULvWv`

**PDAs**:
- Board: `Pubkey::find_program_address(&[b"board"], &program_id)`
- Config: `Pubkey::find_program_address(&[b"config"], &program_id)`
- Treasury: `Pubkey::find_program_address(&[b"treasury"], &program_id)`
- Miner: `Pubkey::find_program_address(&[b"miner", &authority.to_bytes()], &program_id)`
- Round: `Pubkey::find_program_address(&[b"round", &round_id.to_le_bytes()], &program_id)`

## Adding New Tests

### 1. Create Test Function

```rust
#[test]
fn test_my_scenario() -> Result<()> {
    println!("\n🧪 Test: My Scenario");
    println!("══════════════════════════════════════════════════════════\n");
    
    // Test implementation
    
    println!("\n✅ Test passed!\n");
    Ok(())
}
```

### 2. Add to Test Suite

Add function name to `test_suite_summary()` test

### 3. Document

Update this file with test description and validation criteria

## Limitations

### Current

1. **No Full Mainnet Fork**: LiteSVM doesn't support full mainnet state fork
   - Solution: Use `solana-program-test` for complete fork testing

2. **Read-Only Mainnet Queries**: Tests can query but not transact on mainnet
   - Solution: Use simulation or devnet for transaction testing

3. **Network Dependency**: Some tests require mainnet RPC access
   - Solution: Mark as `#[ignore]` or mock mainnet data

### Future Improvements

1. **Integration with solana-program-test**: Full mainnet fork capability
2. **Automated Mainnet Snapshots**: Cache mainnet state for offline testing
3. **Devnet Test Suite**: Deploy and test on devnet automatically
4. **Performance Benchmarks**: Measure instruction execution time
5. **Fuzz Testing**: Random block selection patterns

## Troubleshooting

### "Account not found" Errors

**Cause**: Mainnet RPC not accessible or account doesn't exist

**Solution**:
- Check internet connection
- Verify RPC URL
- Ensure program is deployed on mainnet

### "Deserialization failed" Errors

**Cause**: Account data format changed

**Solution**:
- Verify account discriminator
- Check for program upgrades
- Update struct definitions

### Slow Test Execution

**Cause**: Network latency fetching mainnet accounts

**Solution**:
- Use cached snapshots
- Run tests in parallel
- Use local validator

## Best Practices

1. **Isolate Tests**: Each test should be independent
2. **Clear Output**: Use descriptive println! messages
3. **Comprehensive Assertions**: Validate all state changes
4. **Error Messages**: Provide context in assertion messages
5. **Documentation**: Explain what each test validates

## Related Documentation

- [E2E Flow Analysis](E2E_FLOW_ANALYSIS.md) - Flow validation details
- [Quick Start Guide](QUICKSTART.md) - Getting started
- [Scripts Documentation](SCRIPTS_README.md) - Automation scripts

---

**Last Updated**: 2025-10-22
**Maintained By**: Development Team

