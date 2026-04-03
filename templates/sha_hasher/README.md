# sha_hasher

Computes SHA-256 iteratively inside the ZisK zkVM and generates a proof of correct execution.

See https://0xpolygonhermez.github.io/zisk/getting_started/quickstart.html for full instructions.

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

**Execute** (run the guest program without generating a proof):

```
cargo run --release --bin execute
```

**Emulator** (run via the ZisK emulator with debug output):

```
cargo run --release --bin ziskemu
```

**Verify constraints** (check constraint satisfaction without proof generation):

```
cargo run --release --bin verify-constraints
```

**Generate and verify a proof**:

```
cargo run --release --bin prove
```

**Generate a compressed proof**:

```
cargo run --release --bin compressed
```

**Generate a PLONK SNARK proof** (for on-chain verification):

```
cargo run --release --bin plonk
```

## Structure

```
sha_hasher/
├── guest/src/main.rs    # zkVM program: reads n, computes SHA-256 n times, commits result
└── host/
    ├── src/main.rs      # Default binary: setup, execute, prove, verify
    └── bin/
        ├── execute.rs           # Execute only (no proof)
        ├── ziskemu.rs           # Run via emulator
        ├── verify-constraints.rs # Constraint verification
        ├── prove.rs             # Full proof generation + save/load
        ├── compressed.rs        # Compressed proof
        └── plonk.rs             # PLONK SNARK proof
```
