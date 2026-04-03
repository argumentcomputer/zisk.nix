use anyhow::Result;
use host::{GUEST_AGG, prepare_aggregation_stdin};
use zisk_sdk::{ProofOpts, ProverClient};

fn main() -> Result<()> {
    println!("Starting ZisK Prover Client (Compressed proof mode)...");

    let client = ProverClient::builder().build()?;
    let (agg_pk, agg_vkey) = client.setup(&GUEST_AGG)?;
    let agg_stdin = prepare_aggregation_stdin(&client)?;

    println!("Generating Vadcop proof...");
    let proof_opts = ProofOpts::default().minimal_memory();
    let vadcop_result = client
        .prove(&agg_pk, agg_stdin)
        .with_proof_options(proof_opts)
        .run()?;
    println!("Vadcop proof generated in {:?}", vadcop_result.get_duration());

    println!("Compressing proof (this may take a while)...");
    let compressed_result =
        client.compress(vadcop_result.get_proof(), vadcop_result.get_publics(), &agg_vkey)?;

    println!("Verifying compressed proof...");
    client.verify(
        compressed_result.get_proof(),
        compressed_result.get_publics(),
        compressed_result.get_program_vk(),
    )?;
    println!("Compressed proof verification successful!");

    println!("Successfully generated and verified compressed proof!");

    Ok(())
}
