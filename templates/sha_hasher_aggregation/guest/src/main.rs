// SHA-256 hasher guest program.
// Takes a number `n` and an initial seed, computes SHA-256(seed) `n` times,
// then commits the result.

#![no_main]
ziskos::entrypoint!(main);

use serde::{Deserialize, Serialize};

#[cfg(not(feature = "precompile"))]
use sha2::{Digest, Sha256};

#[derive(Serialize, Deserialize, Debug)]
pub struct ShaOutput {
    pub hash: [u8; 32],
    pub iterations: u32,
}

fn main() {
    let n: u32 = ziskos::io::read();
    let seed: [u8; 32] = ziskos::io::read();

    let mut hash = seed;
    for _ in 0..n {
        #[cfg(feature = "precompile")]
        {
            hash = ziskos::zisklib::sha256(&hash);
        }
        #[cfg(not(feature = "precompile"))]
        {
            let mut hasher = Sha256::new();
            hasher.update(hash);
            hash = hasher.finalize().into();
        }
    }

    let output = ShaOutput { hash, iterations: n };
    ziskos::io::commit(&output);
}
