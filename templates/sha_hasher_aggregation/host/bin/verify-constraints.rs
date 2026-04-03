use anyhow::Result;
use host::GUEST;
use zisk_sdk::ProverClient;

fn main() -> Result<()> {
    println!("Starting ZisK Prover Client...");

    let client = ProverClient::builder().emu().verify_constraints().build()?;
    let (pk, _) = client.setup(&GUEST)?;

    let stdin = host::sha_stdin(100, [0u8; 32]);

    println!("Verifying constraints (no proof generation)...");
    let result = client.verify_constraints(&pk, stdin)?;

    println!("VerifyConstraints completed successfully!");
    println!("Cycles: {}", result.get_execution_steps());
    println!("Duration: {:?}", result.get_duration());

    Ok(())
}
