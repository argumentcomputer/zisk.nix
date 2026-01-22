// Blake3 throughput benchmark: hashes different data sizes with varying iterations

#![no_main]
ziskos::entrypoint!(main);

use ziskos::set_output;

fn main() {
  let data: Vec<u8> = (0..64).map(|i| (i & 0xFF) as u8).collect();
  let hash = blake3::hash(&data);
  let hash = hash.as_bytes();

  // Output final hash as 8 x 32-bit values
  for i in 0..8 {
      let val = u32::from_be_bytes([
          hash[i * 4],
          hash[i * 4 + 1],
          hash[i * 4 + 2],
          hash[i * 4 + 3],
      ]);
      set_output(i, val);
  }
}
