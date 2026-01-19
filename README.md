# zisk.nix

Provides a Nix dev shell and Docker for generating Zisk proofs of Rust programs

## Usage

### Nix dev shell
- Make sure Nix is installed
- Run the dev shell with `nix develop` or direnv
- Check you have `cargo`, `cargo-zisk`, and `ziskemu` available, and that `$ZISK_DIR` is set to `~/.zisk`
- Run the commands from https://0xpolygonhermez.github.io/zisk/getting_started/quickstart.html (pasted below for brevity)
- `cargo run`
- `cargo-zisk build --release`
- `cargo-zisk run --release -i build/input.bin`
- `cargo-zisk rom-setup -e target/riscv64ima-zisk-zkvm-elf/release/sha_hasher`
- `cargo-zisk prove -e target/riscv64ima-zisk-zkvm-elf/release/sha_hasher -i build/input.bin -o proof -a -y -l`
    - Note the added `-l`/`--emulator` option, this prevents memmap issues. `-u`/`--unlock-mapped-memory` works too
    - Total proving time is about 3 minutes for the `sha_hasher` example on my machine, YMMV
- `cargo-zisk verify -p ./proof/vadcop_final_proof.bin`


### Docker

Alternatively, the provided Ubuntu Docker container can be used:
- Build with `nix run .#build-image`. This will take a few minutes to install `ziskup` and download the proving key
- Run the container shell with `nix run .#zisk-shell`
- Build and run per the dev shell instructions
- Exit the container with `exit`

## Troubleshooting
- Run commands with `-v` to get better error messages
- On NixOS, proof gen in the dev shell causes a seg fault `address not mapped to object at address <addr>`. This is likely an MPI version mismatch but does not affect proof generation and can be ignored.
- Try setting `ulimit -l unlimited` per https://0xpolygonhermez.github.io/zisk/getting_started/installation.html#installing-dependencies
- Add `-l` or `-u` to the proof gen command, or it will fail with `ERROR: Failed calling mmap(rom) errno=11=Resource temporarily unavailable` (with `-v`)
- Build and run the Docker image with `nix run .#build-image` and `nix run .#run-zisk`, then install Ziskup via curl. This will give an idea of how the process is supposed to work and what should be available at `~/.zisk`. 

## Notes
- Pure Nix builds are not currently supported, only the dev shell with `cargo-risczero` CLI

## TODOs
- Improve Dockerfile build efficiency with minimal dependencies (see https://github.com/0xPolygonHermez/zisk/blob/main/distributed/Dockerfile)
- Fix NixOS proof gen seg fault (not blocking)
