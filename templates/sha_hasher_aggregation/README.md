# sha_hasher_aggregation

Generates two independent SHA-256 hasher proofs and combines them into a single aggregated proof using recursive verification inside the ZisK zkVM.

## Prerequisites

Enter the dev shell:

```
direnv allow
# or: nix develop
```

## Build

```
cargo build --release
```

To use the ZisK SHA-256 precompile instead of the Rust `sha2` crate:

```
cargo build --release --features precompile
```

## Run

### SHA guest only (no proof generation)

These operate on the SHA-hasher guest directly, without proving or aggregation:

**Execute** (run the SHA guest program):

```
cargo run --release --bin execute
```

**Emulator** (run via the ZisK emulator with debug output):

```
cargo run --release --bin ziskemu
```

**Verify constraints** (check constraint satisfaction):

```
cargo run --release --bin verify-constraints
```

### Full aggregation pipeline (proof generation)

These prove the SHA guest twice, feed both proofs into the aggregation guest, and produce a combined proof:

**Generate and verify an aggregated proof**:

```
cargo run --release --bin prove
```

**Generate a compressed aggregated proof**:

```
cargo run --release --bin compressed
```

**Generate a PLONK SNARK aggregated proof** (for on-chain verification):

```
cargo run --release --bin plonk
```

## How it works

The host generates two independent proofs of the SHA-256 guest program with different inputs. It then packages both proofs using `prepare_send_proof` and passes them as input to `guest_agg`. The aggregation guest runs inside the zkVM, reads both proofs with `read_proof`, and calls `verify_zisk_proof` on each. The resulting single proof attests that both SHA computations were valid.

## Structure

```
sha_hasher_aggregation/
├── guest/src/main.rs         # zkVM program: reads n + seed, computes SHA-256 n times
├── guest_agg/src/main.rs     # zkVM program: reads and verifies two proofs
└── host/
    ├── src/
    │   ├── main.rs           # Default binary: prove + aggregate + verify
    │   └── lib.rs            # Shared helpers and ELF constants
    └── bin/
        ├── execute.rs            # Execute SHA guest (no proof)
        ├── ziskemu.rs            # Run SHA guest via emulator
        ├── verify-constraints.rs # Constraint verification on SHA guest
        ├── prove.rs              # Full aggregated proof generation + save/load
        ├── compressed.rs         # Compressed aggregated proof
        └── plonk.rs              # PLONK SNARK aggregated proof
```
