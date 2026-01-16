# zisk.nix

Provides a Nix dev shell for generating Zisk proofs of Rust programs (WIP)

## Usage
- Make sure Nix is installed
- Run the dev shell with `nix develop` or direnv
- Check you have `cargo`, `cargo-zisk`, and `ziskemu` available, and that `$ZISK_DIR` is set to `~/.zisk`
- Run the commands from https://0xpolygonhermez.github.io/zisk/getting_started/quickstart.html


## Troubleshooting
- Run commands with `-v` to get better error messages
- Set `ulimit -s unlimited` per https://0xpolygonhermez.github.io/zisk/getting_started/installation.html#installing-dependencies
- Add `-u` to the proof gen command or it will fail with `ERROR: Failed calling mmap(rom) errno=11=Resource temporarily unavailable` (with `-v`)
- If you get a segfault on proof gen due to memory mapping issues, that's expected for now
- Build and run the Docker image with `nix run .#build-image` and `nix run .#run-zisk`, then install Ziskup via curl. This will give an idea of how the process is supposed to work and what should be available at `~/.zisk`. 

## Notes
- Pure Nix builds not currently supported, dev shell only
