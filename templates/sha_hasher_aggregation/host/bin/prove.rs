use anyhow::Result;
use host::{GUEST_AGG, prepare_aggregation_stdin};
use zisk_sdk::{ProofOpts, ProverClient, ZiskProofWithPublicValues};

fn main() -> Result<()> {
    println!("Starting ZisK Prover Client...");

    let client = ProverClient::builder().build()?;
    let (agg_pk, _) = client.setup(&GUEST_AGG)?;
    let agg_stdin = prepare_aggregation_stdin(&client)?;

    println!("Generating aggregated proof (this may take a while)...");
    let proof_opts = ProofOpts::default().minimal_memory();
    let result = client
        .prove(&agg_pk, agg_stdin)
        .with_proof_options(proof_opts)
        .run()?;
    println!(
        "Proof generated successfully in {:?}",
        result.get_duration()
    );
    println!("Execution steps: {}", result.get_execution_steps());

    println!("Verifying proof...");
    client.verify(
        result.get_proof(),
        result.get_publics(),
        result.get_program_vk(),
    )?;
    println!("Proof verification successful!");

    println!("Saving proof to disk...");
    result.save_proof_with_publics("tmp/agg_proof_with_publics.bin")?;
    result.get_proof().save("tmp/agg_proof.bin")?;
    println!("Proofs saved to tmp/ directory");

    println!("Loading and verifying saved proof...");
    let vk = client.vk(&GUEST_AGG)?;
    let proof_with_publics = ZiskProofWithPublicValues::load("tmp/agg_proof_with_publics.bin")?;
    client.verify(&proof_with_publics.proof, &proof_with_publics.publics, &vk)?;
    println!("Saved proof verification successful!");

    println!("Successfully generated and verified all proofs!");

    Ok(())
}
