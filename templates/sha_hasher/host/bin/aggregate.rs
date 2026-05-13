use anyhow::Result;
use zisk_sdk::{EmbeddedOpts, GuestProgram, ProverClient, ZiskStdin, load_program};

static LEAF: GuestProgram = load_program!("guest");
static AGGREGATION: GuestProgram = load_program!("aggregation_guest");

#[tokio::main]
async fn main() -> Result<()> {
    let num_proofs: u32 = 2;
    let n_per_leaf: u32 = 100;

    println!(
        "Starting ZisK aggregation: {} leaf proof(s) of {} hash iteration(s) each",
        num_proofs, n_per_leaf
    );

    // Note: avoid `.executor(ExecutorKind::Assembly)` for multi-program flows.
    // The ASM-microservices executor keeps per-program subprocesses keyed by
    // host PID; uploading a second program either collides on shmem names or
    // leaves the first program's rom histogram empty when proving. The default
    // emulator executor multiplexes cleanly across programs.
    println!("Building prover client...");
    let opts = EmbeddedOpts::default().minimal_memory();
    let client = ProverClient::embedded().with_embedded_opts(opts).build()?;

    println!("Setting up leaf program...");
    client.upload(&LEAF).run()?;
    client.setup(&LEAF).run()?.await?;

    println!("Setting up aggregation program...");
    client.upload(&AGGREGATION).run()?;
    client.setup(&AGGREGATION).run()?.await?;

    // Generate N independent leaf proofs.
    let mut leaf_proof_bytes: Vec<Vec<u8>> = Vec::with_capacity(num_proofs as usize);
    for i in 0..num_proofs {
        println!("  [leaf {}/{}] proving...", i + 1, num_proofs);
        let stdin = ZiskStdin::new();
        stdin.write(&n_per_leaf);
        let leaf_result = client.prove(&LEAF, stdin).run()?.await?;
        leaf_proof_bytes.push(leaf_result.get_proof_bytes());
    }

    // Build aggregation stdin: u32 count followed by each proof as Vec<u8>.
    let agg_stdin = ZiskStdin::new();
    agg_stdin.write(&num_proofs);
    for bytes in &leaf_proof_bytes {
        agg_stdin.write(bytes);
    }

    println!("Aggregating {} proofs in-circuit...", num_proofs);
    let agg_result = client.prove(&AGGREGATION, agg_stdin).run()?.await?;

    println!("Verifying aggregate proof...");
    agg_result.verify()?;
    println!("Aggregate proof verification successful!");

    println!(
        "\u{2713} Successfully aggregated and verified {} leaf proof(s)!",
        num_proofs
    );
    Ok(())
}
