# zisk.nix

Provides a Nix dev shell and Docker shell image for generating Zisk proofs of
Rust programs

## Prerequisites

8+ CPU cores and 64+ GB RAM

## Usage

### Nix dev shell

- Make sure Nix is installed with flakes support
- Run the dev shell with `nix develop` or direnv, optionally with the
  argumentcomputer Cachix cache
- Check you have `cargo`, `cargo-zisk`, and `ziskemu` available, and that
  `$ZISK_DIR` is set to `~/.zisk`
- Run the commands from
  https://0xpolygonhermez.github.io/zisk/getting_started/quickstart.html
  - Total proving time is about 5 minutes for the `sha_hasher` example on my
    machine, YMMV

### Docker

Alternatively, the provided Ubuntu Docker container can be used:

- Run the container shell with `nix run .#zisk-shell`. On first use this pulls
  the CI-published image from `ghcr.io/argumentcomputer/cargo-zisk:main` — no
  local image build needed. Pass `--cpu`/`--gpu` and `--key` to install the
  Zisk binaries and setup keys via `ziskup` inside the container (see
  `zisk-shell --help`)
- To build the image locally instead, run `nix run .#build-image`, then use
  `ZISK_IMAGE=localhost/cargo-zisk:latest nix run .#zisk-shell`
- Build and run per the dev shell instructions
- Exit the container with `exit`. The container keeps running; remove it with
  `podman kill zisk-dev && podman rm zisk-dev`

The wrappers drive a Nix-provided rootless podman, so they work without any
container engine installed on the host (rootless podman only needs
`/etc/subuid`/`/etc/subgid` entries for your user). If you have Docker — or
your own podman — set up, you can use it directly with the same Dockerfile and
image: e.g. `docker build -f docker/Dockerfile -t cargo-zisk .` or
`docker run -it ghcr.io/argumentcomputer/cargo-zisk:main`. CI builds, tests,
and publishes this image with Docker; the engines are interchangeable.

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
