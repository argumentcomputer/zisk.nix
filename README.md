# zisk.nix

Provides a Nix dev shell and Docker shell image for generating Zisk proofs of
Rust programs

## Prerequisites

8+ CPU cores and 64+ GB RAM

## Usage

### Nix dev shell

- Make sure Nix is installed with flakes support
- Run the dev shell with `nix develop` or direnv, optionally with Garnix cache
- Check you have `cargo`, `cargo-zisk`, and `ziskemu` available, and that
  `$ZISK_DIR` is set to `~/.zisk`
- Run the commands from
  https://0xpolygonhermez.github.io/zisk/getting_started/quickstart.html
  - Total proving time is about 5 minutes for the `sha_hasher` example on my
    machine, YMMV

### Docker

Alternatively, the provided Ubuntu Docker container can be used:

- Build with `nix run .#build-image`. This will take a few minutes to install
  `ziskup` and download the proving key
- Run the container shell with `nix run .#zisk-shell`
- Build and run per the dev shell instructions
- Exit the container with `exit`

## Troubleshooting

- Run commands with `-v` to get better error messages
- On NixOS, proof gen in the dev shell may cause unexpected errors or warnings.
  These can often be ignored if they don't affect proof generation
- Add `-l` or `-u` to the proof gen command if you get
  `ERROR: Failed calling mmap(rom) errno=11=Resource temporarily unavailable`
  (logs shown with `-v`)
- Try setting `ulimit -l unlimited` per
  https://0xpolygonhermez.github.io/zisk/getting_started/installation.html#installing-dependencies

## Notes

- Pure Nix builds are not currently supported, only the dev shell with `cargo/cargo-zisk` CLI
- For best performance use the Docker container, especially when compiling Zisk from source for GPU proving

## TODOs

- Improve Dockerfile build efficiency with minimal dependencies (see
  https://github.com/0xPolygonHermez/zisk/blob/main/distributed/Dockerfile)
- Add GPU proving to the Nix dev shell
- Test for any Nix-related performance regressions
