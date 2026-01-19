FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Base Zisk dependencies
RUN apt-get update && apt-get install -y \
    xz-utils jq curl build-essential qemu-system \
    libomp-dev libgmp-dev nlohmann-json3-dev protobuf-compiler \
    uuid-dev libgrpc++-dev libsecp256k1-dev libsodium-dev \
    libpqxx-dev nasm libopenmpi-dev openmpi-bin openmpi-common \
    libclang-dev clang gcc-riscv64-unknown-elf git \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install ZisK via ziskup
# Set SETUP_KEY environment variable to bypass TTY prompt
RUN curl -fsSL https://raw.githubusercontent.com/0xPolygonHermez/zisk/main/ziskup/install.sh -o /tmp/install.sh && \
    SETUP_KEY=proving bash /tmp/install.sh && \
    rm /tmp/install.sh
ENV PATH="/root/.zisk/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]
