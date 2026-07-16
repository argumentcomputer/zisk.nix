FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

# Base Zisk dependencies
# Source: https://0xpolygonhermez.github.io/zisk/getting_started/installation.html
# pkg-config/libssl-dev on top of the book's list: needed to cargo-build SDK
# host programs (openssl-sys) inside the container.
RUN apt-get update && apt-get install -y \
    xz-utils jq curl build-essential qemu-system \
    libomp-dev libgmp-dev nlohmann-json3-dev protobuf-compiler \
    uuid-dev libgrpc++-dev libsecp256k1-dev libsodium-dev \
    libpqxx-dev nasm libopenmpi-dev openmpi-bin openmpi-common \
    libclang-dev clang gcc-riscv64-unknown-elf git \
    pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install the ziskup installer, pinned to the argumentcomputer fork rev the
# rest of this repo tracks (the fork's ziskup honors the ZISK_VERSION/SETUP_KEY
# env vars and key modes that zisk-shell relies on). Binaries and setup keys
# are not installed at build time — run `ziskup` inside the container (or
# invoke zisk-shell with --gpu/--cpu/--key) to choose them. ziskup installs
# the ZISK_VERSION *upstream* release binaries and its matching key from the
# upstream bucket (the fork publishes no releases).
ARG ZISK_FORK_REV=e4057c4cd6daaa29ea54f283ff27818acc9be8b2
ARG ZISK_VERSION=1.0.0-alpha
ENV ZISK_VERSION=${ZISK_VERSION}
RUN mkdir -p /root/.zisk/bin && \
    curl -fsSL "https://raw.githubusercontent.com/argumentcomputer/zisk/${ZISK_FORK_REV}/ziskup/ziskup" \
      -o /root/.zisk/bin/ziskup && \
    chmod +x /root/.zisk/bin/ziskup
ENV PATH="/root/.zisk/bin:${PATH}"

# Installer for the fork-matching proving key (extra Blake3f AIR), mirroring
# this repo's `nix run .#install-proving-key`. Use it INSTEAD of ziskup's key
# install when the prover is built from the fork sources (e.g. an SDK host
# linking zisk-sdk from the blake3-precompile branch); use ziskup's upstream
# key for the upstream release binaries. Both keys land in
# $ZISK_DIR/provingKey — the last one installed wins.
# The tarball omits the const-tree files; check-setup (from the ziskup-installed
# binaries, so run `ziskup` first) regenerates them.
RUN cat > /root/.zisk/bin/install-proving-key <<'EOF' && chmod +x /root/.zisk/bin/install-proving-key
#!/usr/bin/env bash
set -euo pipefail
ZISK_DIR="${ZISK_DIR:-$HOME/.zisk}"
command -v cargo-zisk-dev >/dev/null || {
  echo "cargo-zisk-dev not found - run 'ziskup --nokey' first" >&2
  exit 1
}
KEY_FILE="zisk-provingkey-blake3-e4057c4c-cpu.tar.gz"
echo "Downloading fork proving key to $ZISK_DIR (this may take a while)..."
curl -fSL --retry 3 -o "/tmp/$KEY_FILE" \
  "https://argument-zisk-setup.s3.amazonaws.com/$KEY_FILE"
rm -rf "$ZISK_DIR/provingKey"
tar -C "$ZISK_DIR" -xzf "/tmp/$KEY_FILE"
rm -f "/tmp/$KEY_FILE"
echo "Generating constant tree..."
cargo-zisk-dev check-setup --proving-key "$ZISK_DIR/provingKey" -a
echo "Proving key setup complete."
EOF

WORKDIR /workspace

CMD ["/bin/bash"]
