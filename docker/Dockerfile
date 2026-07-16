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

# Install the ziskup installer pinned to the Zisk release (its ziskup honors
# the ZISK_VERSION/SETUP_KEY env vars and key modes that zisk-shell relies
# on). Binaries and setup keys are not installed at build time — run `ziskup`
# inside the container (or invoke zisk-shell with --gpu/--cpu/--key) to choose
# them. Upstream install.sh always fetches ziskup from main, so we fetch from
# the tag.
ARG ZISK_VERSION=1.0.0-alpha
ENV ZISK_VERSION=${ZISK_VERSION}
RUN mkdir -p /root/.zisk/bin && \
    curl -fsSL "https://raw.githubusercontent.com/0xPolygonHermez/zisk/v${ZISK_VERSION}/ziskup/ziskup" \
      -o /root/.zisk/bin/ziskup && \
    chmod +x /root/.zisk/bin/ziskup
ENV PATH="/root/.zisk/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]
