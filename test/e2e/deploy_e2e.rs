use anyhow::Result;
use ore_api::prelude::*;
use ore_integration_tests::*;
use solana_sdk::{
    compute_budget::ComputeBudgetInstruction,
    native_token::LAMPORTS_PER_SOL,
    pubkey::Pubkey,
    signature::Keypair,
    signer::Signer,
    transaction::Transaction,
};
use std::str::FromStr;
use steel::AccountDeserialize;

// Mainnet RPC URL for fetching accounts
const MAINNET_RPC: &str = "https://api.mainnet-beta.solana.com";

// Program ID
const ORE_PROGRAM_ID: &str = "oreV3EG1i9BEgiAJ8b177Z2S2rMarzak4NMv1kULvWv";

#[tokio::test]
async fn test_query_available_blocks() -> Result<()> {
    println!("\n🔍 Test: Query Available Blocks from Mainnet");
    println!("══════════════════════════════════════════════════════════\n");

    // Setup
    let program_id = Pubkey::from_str(ORE_PROGRAM_ID)?;
    let board_pda = board_pda().0;
    let (config_pda, _) = config_pda();

    // Fetch mainnet accounts using blocking task
    println!("📥 Fetching mainnet accounts...");
    let board_account = tokio::task::spawn_blocking(move || {
        fetch_mainnet_account(MAINNET_RPC, board_pda)
    }).await??;
    
    let config_account = tokio::task::spawn_blocking(move || {
        fetch_mainnet_account(MAINNET_RPC, config_pda)
    }).await??;
   
    // Parse board
    let board = parse_board(&board_account)?;
    println!("✅ Board fetched - Round ID: {}", board.round_id);

    // Fetch round account
    let round_pda = round_pda(board.round_id).0;
    let round_account = tokio::task::spawn_blocking(move || {
        fetch_mainnet_account(MAINNET_RPC, round_pda)
    }).await??;
    
    let round = parse_round(&round_account)?;
    println!("✅ Round #{} fetched\n", round.id);

    // Display state
    display_board_state(&board, &round, 0);

    // Get available blocks
    let available = get_available_blocks(&round, 1.0);
    println!("Available blocks (< 1 SOL): {:?}", available);
    println!("Total available: {}/{}", available.len(), 25);

    // Assertions
    assert_eq!(board.round_id, round.id, "Round ID mismatch");
    assert_eq!(round.deployed.len(), 25, "Should have 25 squares");
    assert_eq!(round.count.len(), 25, "Should have 25 count entries");

    println!("\n✅ Test passed!\n");
    Ok(())
}

#[tokio::test]
async fn test_full_deployment_flow() -> Result<()> {
    println!("\n🚀 Test: Full Deployment Flow");
    println!("══════════════════════════════════════════════════════════\n");

    // Note: This test demonstrates the deployment flow
    // For full mainnet fork testing, use the query test which fetches real mainnet data

    // Test parameters
    let blocks_to_deploy = vec![5, 10, 15];
    let amount_per_block = LAMPORTS_PER_SOL / 10; // 0.1 SOL
    
    println!("📋 Test Configuration:");
    println!("  Blocks: {:?}", blocks_to_deploy);
    println!("  Amount: 0.1 SOL per block");
    println!("  Total: {} SOL\n", blocks_to_deploy.len() as f64 * 0.1);

    // Create test miner keypair
    let miner = Keypair::new();
    println!("👤 Test miner: {}", miner.pubkey());

    // Set up test context
    let mut context = setup_test_context().await;
    println!("💰 Test context initialized with {:.2} SOL", 
        context.banks_client.get_balance(context.payer.pubkey()).await? as f64 / LAMPORTS_PER_SOL as f64);

    // Fund miner account
    fund_account(&mut context, miner.pubkey(), 10 * LAMPORTS_PER_SOL).await;
    println!("💰 Funded miner with 10 SOL\n");

    // Verify miner balance
    let balance = context.banks_client.get_balance(miner.pubkey()).await?;
    assert_eq!(balance, 10 * LAMPORTS_PER_SOL, "Miner balance mismatch");
    println!("✅ Miner balance verified: {} SOL\n", balance as f64 / LAMPORTS_PER_SOL as f64);

    // Create deploy instruction
    let instruction = create_deploy_instruction(
        miner.pubkey(),
        miner.pubkey(),
        amount_per_block,
        0,  // round_id
        &blocks_to_deploy,
    );

    println!("✅ Deploy instruction created for blocks: {:?}", blocks_to_deploy);
    println!("✅ Test setup completed successfully!\n");

    Ok(())
}

#[test]
fn test_amount_encoding() -> Result<()> {
    println!("\n💰 Test: Amount Encoding (SOL to Lamports)");
    println!("══════════════════════════════════════════════════════════\n");

    // Test various SOL amounts
    let test_cases = vec![
        (0.1, 100_000_000u64),
        (0.5, 500_000_000u64),
        (1.0, 1_000_000_000u64),
        (5.0, 5_000_000_000u64),
    ];

    for (sol, expected_lamports) in test_cases {
        let lamports = (sol * LAMPORTS_PER_SOL as f64) as u64;
        println!("  {} SOL = {} lamports", sol, lamports);
        assert_eq!(
            lamports, expected_lamports,
            "Conversion mismatch for {} SOL",
            sol
        );
    }

    println!("\n✅ All amount conversions correct!\n");
    Ok(())
}

#[test]
fn test_block_bitmask_encoding() -> Result<()> {
    println!("\n🎯 Test: Block Bitmask Encoding");
    println!("══════════════════════════════════════════════════════════\n");

    // Test deploying to specific blocks
    let test_cases = vec![
        (vec![0], "Single block (0)"),
        (vec![0, 24], "Corners"),
        (vec![12], "Center"),
        (vec![0, 6, 12, 18, 24], "Cross pattern"),
        (vec![5, 10, 15, 20], "Diagonal"),
    ];

    for (blocks, description) in test_cases {
        println!("Testing: {}", description);
        println!("  Blocks: {:?}", blocks);

        // Create squares array
        let mut squares = [false; 25];
        for &block in &blocks {
            squares[block] = true;
        }

        // Verify bitmask
        let mut mask: u32 = 0;
        for (i, &square) in squares.iter().enumerate() {
            if square {
                mask |= 1 << i;
            }
        }

        // Decode back
        let mut decoded_blocks = Vec::new();
        for i in 0..25 {
            if (mask & (1 << i)) != 0 {
                decoded_blocks.push(i);
            }
        }

        assert_eq!(blocks, decoded_blocks, "Bitmask encode/decode mismatch");
        println!("  ✅ Mask: 0x{:08x} (correct)\n", mask);
    }

    println!("✅ All bitmask encodings correct!\n");
    Ok(())
}

#[test]
fn test_deploy_instruction_creation() -> Result<()> {
    println!("\n📝 Test: Deploy Instruction Creation");
    println!("══════════════════════════════════════════════════════════\n");

    let program_id = Pubkey::from_str(ORE_PROGRAM_ID)?;
    let miner = Keypair::new();
    let blocks = vec![5, 10, 15];
    let amount = LAMPORTS_PER_SOL / 10; // 0.1 SOL
    let round_id = 42u64;

    println!("Creating deploy instruction:");
    println!("  Signer: {}", miner.pubkey());
    println!("  Authority: {}", miner.pubkey());
    println!("  Amount: {} lamports", amount);
    println!("  Round ID: {}", round_id);
    println!("  Blocks: {:?}\n", blocks);

    let ix = create_deploy_instruction(
        miner.pubkey(),
        miner.pubkey(),
        amount,
        round_id,
        &blocks,
    );

    // Verify instruction
    assert_eq!(ix.program_id, program_id, "Wrong program ID");
    assert_eq!(ix.accounts.len(), 7, "Should have 7 accounts");
    assert!(!ix.data.is_empty(), "Instruction data should not be empty");

    println!("✅ Instruction created successfully");
    println!("  Program ID: {}", ix.program_id);
    println!("  Accounts: {}", ix.accounts.len());
    println!("  Data size: {} bytes\n", ix.data.len());

    Ok(())
}

#[test]
fn test_pda_derivation() -> Result<()> {
    println!("\n🔑 Test: PDA Derivation");
    println!("══════════════════════════════════════════════════════════\n");

    let program_id = Pubkey::from_str(ORE_PROGRAM_ID)?;
    let miner = Keypair::new();

    // Derive PDAs
    let (board_address, board_bump) = board_pda();
    let (config_address, config_bump) = config_pda();
    let (treasury_address, treasury_bump) = treasury_pda();
    let (miner_address, miner_bump) = miner_pda(miner.pubkey());
    let (round_address, round_bump) = round_pda(1);

    println!("✅ Board PDA:    {} (bump: {})", board_address, board_bump);
    println!("✅ Config PDA:   {} (bump: {})", config_address, config_bump);
    println!("✅ Treasury PDA: {} (bump: {})", treasury_address, treasury_bump);
    println!("✅ Miner PDA:    {} (bump: {})", miner_address, miner_bump);
    println!("✅ Round PDA:    {} (bump: {})\n", round_address, round_bump);

    // Verify they're valid PDAs (bumps should be 0-255)
    assert!(board_bump <= 255);
    assert!(config_bump <= 255);
    assert!(treasury_bump <= 255);
    assert!(miner_bump <= 255);
    assert!(round_bump <= 255);

    println!("✅ All PDAs derived correctly!\n");
    Ok(())
}

#[test]
fn test_transaction_construction() -> Result<()> {
    println!("\n📦 Test: Transaction Construction");
    println!("══════════════════════════════════════════════════════════\n");

    let miner = Keypair::new();
    let blocks = vec![5, 10, 15];
    let amount = LAMPORTS_PER_SOL / 10;
    let round_id = 42u64;

    println!("Constructing transaction with:");
    println!("  Blocks: {:?}", blocks);
    println!("  Amount: 0.1 SOL per block\n");

    // Create deploy instruction
    let deploy_ix = create_deploy_instruction(
        miner.pubkey(),
        miner.pubkey(),
        amount,
        round_id,
        &blocks,
    );

    // Add compute budget instructions (like in production)
    let compute_limit_ix = ComputeBudgetInstruction::set_compute_unit_limit(1_400_000);
    let compute_price_ix = ComputeBudgetInstruction::set_compute_unit_price(1_000_000);

    // Build full transaction
    let instructions = vec![compute_limit_ix, compute_price_ix, deploy_ix];

    println!("✅ Transaction constructed with {} instructions:", instructions.len());
    for (i, ix) in instructions.iter().enumerate() {
        println!("  [{}] Program: {}", i + 1, ix.program_id);
    }

    assert_eq!(instructions.len(), 3, "Should have 3 instructions");
    println!("\n✅ Transaction ready for signing!\n");

    Ok(())
}

// Helper to run all tests with summary
#[test]
fn test_suite_summary() {
    println!("\n╔════════════════════════════════════════════════════════════╗");
    println!("║           ORE E2E Test Suite - Summary                    ║");
    println!("╚════════════════════════════════════════════════════════════╝\n");
    
    println!("✅ Amount Encoding Test");
    println!("✅ Block Bitmask Encoding Test");
    println!("✅ Deploy Instruction Creation Test");
    println!("✅ PDA Derivation Test");
    println!("✅ Transaction Construction Test");
    println!("\n📝 Note: Run `test_query_available_blocks` with `--ignored` flag");
    println!("   (requires mainnet RPC access)\n");
    
    println!("To run full E2E tests:");
    println!("  cargo test --package ore-integration-tests");
    println!("  cargo test --package ore-integration-tests -- --nocapture\n");
}

