use anyhow::Result;
use litesvm::LiteSVM;
use ore_api::prelude::*;
use solana_client::rpc_client::RpcClient;
use solana_sdk::{
    account::Account,
    native_token::lamports_to_sol,
    pubkey::Pubkey,
    signature::{Keypair, Signature},
    signer::Signer,
    system_instruction,
    transaction::Transaction,
};
use steel::AccountDeserialize;

/// Fetch account data from mainnet via RPC
pub async fn fetch_mainnet_account(rpc_url: &str, address: Pubkey) -> Result<Account> {
    let client = RpcClient::new(rpc_url.to_string());
    let account = client.get_account(&address)?;
    Ok(account)
}

/// Create and configure LiteSVM test context
pub fn setup_test_context() -> LiteSVM {
    LiteSVM::new()
}

/// Fund an account with SOL
pub fn fund_account(svm: &mut LiteSVM, pubkey: Pubkey, lamports: u64) {
    let ix = system_instruction::transfer(&svm.payer(), &pubkey, lamports);
    let tx = Transaction::new_signed_with_payer(
        &[ix],
        Some(&svm.payer()),
        &[&svm.payer_keypair()],
        svm.latest_blockhash(),
    );
    svm.send_transaction(tx).unwrap();
}

/// Add account to LiteSVM from mainnet data
pub fn add_mainnet_account(svm: &mut LiteSVM, address: Pubkey, account: Account) {
    svm.set_account(address, account).unwrap();
}

/// Pretty print board state
pub fn display_board_state(board: &Board, round: &Round, slot: u64) {
    println!("\n╔════════════════════════════════════════════════════════════╗");
    println!("║                      Board State                           ║");
    println!("╚════════════════════════════════════════════════════════════╝");
    println!("Round ID: {}", board.round_id);
    println!("Start Slot: {}", board.start_slot);
    println!("End Slot: {}", board.end_slot);
    println!("Current Slot: {}", slot);
    println!(
        "Time Remaining: {:.1} sec",
        (board.end_slot.saturating_sub(slot) as f64) * 0.4
    );
    println!("\n╔════════════════════════════════════════════════════════════╗");
    println!("║                      Round State                           ║");
    println!("╚════════════════════════════════════════════════════════════╝");
    println!("Round #{}", round.id);
    println!("Total Deployed: {} SOL", lamports_to_sol(round.total_deployed));
    println!("Expires At: {}", round.expires_at);
    println!("\nBlock Deployment Status:");
    println!("┌──────┬─────────────┬───────┐");
    println!("│ Block│ Deployed    │ Count │");
    println!("├──────┼─────────────┼───────┤");
    for (i, (&deployed, &count)) in round.deployed.iter().zip(&round.count).enumerate() {
        let status = if deployed == 0 {
            "AVAILABLE  ".to_string()
        } else {
            format!("{:>8.4} SOL", lamports_to_sol(deployed))
        };
        println!("│ {:>4} │ {} │ {:>5} │", i, status, count);
    }
    println!("└──────┴─────────────┴───────┘\n");
}

/// Display deployment summary
pub fn display_deployment_summary(blocks: &[usize], amount: u64, sigs: &[Signature]) {
    println!("\n╔════════════════════════════════════════════════════════════╗");
    println!("║                  Deployment Summary                        ║");
    println!("╚════════════════════════════════════════════════════════════╝");
    println!("Blocks Deployed: {:?}", blocks);
    println!("Amount per Block: {} SOL", lamports_to_sol(amount));
    println!("Total Deployed: {} SOL", lamports_to_sol(amount * blocks.len() as u64));
    println!("\nTransaction Signatures:");
    for (i, sig) in sigs.iter().enumerate() {
        println!("  [{}] {}", i + 1, sig);
    }
    println!();
}

/// Parse board account from account data
pub fn parse_board(account: &Account) -> Result<Board> {
    let board = Board::try_from_bytes(&account.data)?;
    Ok(*board)
}

/// Parse round account from account data
pub fn parse_round(account: &Account) -> Result<Round> {
    let round = Round::try_from_bytes(&account.data)?;
    Ok(*round)
}

/// Parse miner account from account data
pub fn parse_miner(account: &Account) -> Result<Miner> {
    let miner = Miner::try_from_bytes(&account.data)?;
    Ok(*miner)
}

/// Get available blocks (where deployed amount is below threshold)
pub fn get_available_blocks(round: &Round, threshold_sol: f64) -> Vec<usize> {
    let threshold_lamports = (threshold_sol * 1_000_000_000.0) as u64;
    round
        .deployed
        .iter()
        .enumerate()
        .filter(|(_, &deployed)| deployed < threshold_lamports)
        .map(|(i, _)| i)
        .collect()
}

/// Create deploy instruction with proper encoding
pub fn create_deploy_instruction(
    signer: Pubkey,
    authority: Pubkey,
    amount_lamports: u64,
    round_id: u64,
    blocks: &[usize],
) -> solana_sdk::instruction::Instruction {
    // Create squares array (25 bools)
    let mut squares = [false; 25];
    for &block in blocks {
        if block < 25 {
            squares[block] = true;
        }
    }

    ore_api::sdk::deploy(signer, authority, amount_lamports, round_id, squares)
}

/// Verify deployment in round state
pub fn verify_deployment(
    old_round: &Round,
    new_round: &Round,
    blocks: &[usize],
    amount: u64,
) -> Result<()> {
    for &block in blocks {
        let old_deployed = old_round.deployed[block];
        let new_deployed = new_round.deployed[block];
        let expected_deployed = old_deployed + amount;

        assert_eq!(
            new_deployed, expected_deployed,
            "Block {} deployment mismatch. Expected: {}, Got: {}",
            block, expected_deployed, new_deployed
        );

        let old_count = old_round.count[block];
        let new_count = new_round.count[block];
        assert_eq!(
            new_count,
            old_count + 1,
            "Block {} count mismatch. Expected: {}, Got: {}",
            block,
            old_count + 1,
            new_count
        );
    }
    Ok(())
}

/// Verify miner state after deployment
pub fn verify_miner_state(
    miner: &Miner,
    blocks: &[usize],
    amount: u64,
    round_id: u64,
) -> Result<()> {
    assert_eq!(
        miner.round_id, round_id,
        "Miner round_id mismatch. Expected: {}, Got: {}",
        round_id, miner.round_id
    );

    for &block in blocks {
        assert_eq!(
            miner.deployed[block], amount,
            "Miner block {} deployment mismatch. Expected: {}, Got: {}",
            block, amount, miner.deployed[block]
        );
    }

    Ok(())
}

