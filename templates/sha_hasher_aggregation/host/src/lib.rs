use anyhow::Result;
use zisk_sdk::{ElfBinary, ProofOpts, ZiskBackend, ZiskProver, ZiskStdin, include_elf};

pub const GUEST: ElfBinary = include_elf!("guest");
pub const GUEST_AGG: ElfBinary = include_elf!("guest_agg");

/// Create a ZiskStdin for the SHA-hasher guest with the given iterations and seed.
pub fn sha_stdin(iterations: u32, seed: [u8; 32]) -> ZiskStdin {
    let stdin = ZiskStdin::new();
    stdin.write(&iterations);
    stdin.write(&seed);
    stdin
}

/// Generate two SHA-hasher proofs and return the aggregation stdin.
///
/// NOTE: This always proves the two inner SHA programs.
/// The aggregation guest requires real proofs as input.
pub fn prepare_aggregation_stdin(client: &ZiskProver<impl ZiskBackend>) -> Result<ZiskStdin> {
    println!("Preparing inner proofs (required as input for aggregation guest)...");
    let (sha_pk, sha_vkey) = client.setup(&GUEST)?;

    // First SHA proof: 100 iterations, seed = all zeros
    let stdin1 = sha_stdin(100, [0u8; 32]);

    println!("Generating first SHA-hasher proof (100 iterations, zero seed)...");
    let proof_opts = ProofOpts::default().minimal_memory();
    let result1 = client.prove(&sha_pk, stdin1).with_proof_options(proof_opts).run()?;
    println!("First proof generated.");

    // Second SHA proof: 200 iterations, seed = [1; 32]
    let stdin2 = sha_stdin(200, [1u8; 32]);

    println!("Generating second SHA-hasher proof (200 iterations, ones seed)...");
    let proof_opts = ProofOpts::default().minimal_memory();
    let result2 = client.prove(&sha_pk, stdin2).with_proof_options(proof_opts).run()?;
    println!("Second proof generated.");
    println!("Inner proofs ready.");

    // Package both proofs as aggregation input
    let prepared1 =
        client.prepare_send_proof(&result1.get_proof(), &result1.get_publics(), &sha_vkey)?;
    let prepared2 =
        client.prepare_send_proof(&result2.get_proof(), &result2.get_publics(), &sha_vkey)?;

    let agg_stdin = ZiskStdin::new();
    agg_stdin.write_proof(&prepared1);
    agg_stdin.write_proof(&prepared2);

    Ok(agg_stdin)
}
