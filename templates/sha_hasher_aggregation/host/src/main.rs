// Host program: generates two independent SHA-hasher proofs with different
// inputs, then aggregates them into a single proof by feeding both into the
// aggregation guest which verifies them inside the zkVM.

use anyhow::Result;
use host::{GUEST_AGG, prepare_aggregation_stdin};
use zisk_sdk::{ProofOpts, ProverClient};

fn main() -> Result<()> {
    println!("Starting ZisK Prover Client...");

    let client = ProverClient::builder().build()?;
    let (agg_pk, agg_vkey) = client.setup(&GUEST_AGG)?;
    let agg_stdin = prepare_aggregation_stdin(&client)?;

    println!("Generating aggregated proof...");
    let proof_opts = ProofOpts::default().minimal_memory();
    let agg_result = client
        .prove(&agg_pk, agg_stdin)
        .with_proof_options(proof_opts)
        .run()?;

    println!("Verifying aggregated proof...");
    client.verify(agg_result.get_proof(), agg_result.get_publics(), &agg_vkey)?;

    println!("Successfully generated and verified aggregated proof!");

    Ok(())
}
