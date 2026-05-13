# sha_hasher

A ZisK 0.17 example: iteratively computes SHA-256 inside the zkVM and generates
a proof of correct execution. Includes an aggregation guest that verifies N
leaf proofs in-circuit to produce a single top-level proof.

See https://0xpolygonhermez.github.io/zisk/getting_started/quickstart.html for
upstream docs.

## Prerequisites

Enter the dev shell (provides `cargo-zisk`, `ziskemu`, the Zisk Rust toolchain,
and all native deps):

```
direnv allow
# or: nix develop
```

For proving you also need the proving key:

```
nix run .#install-proving-key
```

## Build

```
cargo build --release
```

## Run

The host crate exposes several bins, each demonstrating a different proving
mode. Each bin writes its own fixed input to stdin — edit the corresponding
file under `host/bin/` to change it.

**Run via emulator** (no proof):

```
cargo run --release --bin run
```

**Execute under the SDK** (no proof generation, but full setup):

```
cargo run --release --bin execute
```

**Generate and verify a basic-stage proof**:

```
cargo run --release --bin prove
```

**Wrap into a minimal recursive proof**:

```
cargo run --release --bin minimal
```

**Wrap into a PLONK SNARK proof** (for on-chain verification):

```
cargo run --release --bin plonk
```

**Aggregate N leaf proofs** (generates N independent leaf proofs, then proves
their joint verification inside the aggregation guest):

```
cargo run --release --bin aggregate
```

## Structure

```
sha_hasher/
├── common/                       # Shared Output type (ABI-encoded)
├── guest/                        # Leaf zkVM program (SHA-256 iteration)
├── aggregation_guest/            # Aggregation zkVM program (verify_zisk_proof)
└── host/
    ├── src/main.rs               # Default binary: full setup + prove + verify
    └── bin/
        ├── run.rs                # Standalone emulator
        ├── execute.rs            # Execute only (no proof)
        ├── prove.rs              # Basic-stage proof
        ├── minimal.rs            # VadcopFinalMinimal wrapped proof
        ├── plonk.rs              # PLONK SNARK proof
        └── aggregate.rs          # Aggregate N leaf proofs in-circuit
```
