// Aggregation guest: reads `num_proofs` followed by that many `Vec<u8>` proof
// blobs from stdin and verifies each one inside the zkVM via
// `ziskos::io::verify_zisk_proof`. Each blob must be the bytes returned by
// `vadcop_result.get_proof_bytes()` on the host, which is already in the
// `[minimal(8)][pubs_len(8)][pubs][proof_bytes][zisk_vk]` format understood
// by `verify_zisk_proof`.
//
// Commits `num_proofs` so the publics show how many leaves the aggregate
// proof attests to.

#![no_main]
ziskos::entrypoint!(main);

extern crate alloc;
use alloc::vec::Vec;

fn main() {
    let num_proofs: u32 = ziskos::io::read();

    for i in 0..num_proofs {
        let proof: Vec<u8> = ziskos::io::read();
        if !ziskos::io::verify_zisk_proof(&proof) {
            panic!("Proof {} verification failed", i);
        }
    }

    ziskos::io::commit(&num_proofs);
}
