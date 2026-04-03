// Aggregation guest: reads two SHA-hasher proofs from input, verifies both
// inside the zkVM, and commits a success flag.
//
// This proves that both SHA computations were performed correctly without
// the verifier needing to check each proof individually.

#![no_main]
ziskos::entrypoint!(main);

fn main() {
    // Read and verify the first SHA-hasher proof
    let proof1 = ziskos::io::read_proof();
    if !ziskos::io::verify_zisk_proof(&proof1) {
        panic!("First SHA-hasher proof verification failed");
    }

    // Read and verify the second SHA-hasher proof
    let proof2 = ziskos::io::read_proof();
    if !ziskos::io::verify_zisk_proof(&proof2) {
        panic!("Second SHA-hasher proof verification failed");
    }

    // Commit success: both proofs verified
    let verified: u32 = 1;
    ziskos::io::commit(&verified);
}
