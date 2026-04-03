use anyhow::Result;
use host::{GUEST_AGG, prepare_aggregation_stdin};
use zisk_sdk::{ProverClient, ZiskProofWithPublicValues};

fn main() -> Result<()> {
    println!("Starting ZisK Prover Client (SNARK mode)...");

    let client = ProverClient::builder().snark().build()?;
    let (agg_pk, agg_vkey) = client.setup(&GUEST_AGG)?;
    let agg_stdin = prepare_aggregation_stdin(&client)?;

    println!("Generating PLONK proof (this may take a while)...");
    let snark_proof = client.prove(&agg_pk, agg_stdin).plonk().run()?;
    println!("PLONK proof generated successfully in {:?}", snark_proof.get_duration());
    println!("Execution steps: {}", snark_proof.get_execution_steps());

    println!("Verifying PLONK proof...");
    client.verify(snark_proof.get_proof(), snark_proof.get_publics(), &agg_vkey)?;
    println!("PLONK proof verification successful!");

    println!("Saving PLONK proof to disk...");
    snark_proof.save_proof_with_publics("tmp/agg_proof_snark_with_publics.bin")?;
    println!("Proof saved to tmp/agg_proof_snark_with_publics.bin");

    println!("Loading and verifying saved PLONK proof...");
    let proof = ZiskProofWithPublicValues::load("tmp/agg_proof_snark_with_publics.bin")?;
    let vk = client.vk(&GUEST_AGG)?;
    client.verify(proof.get_proof(), proof.get_publics(), &vk)?;
    println!("Saved PLONK proof verification successful!");

    println!("Successfully generated and verified PLONK proof!");

    Ok(())
}
