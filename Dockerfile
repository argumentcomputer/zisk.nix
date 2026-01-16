# TODO: Proving doesn't work due to network error:
# ```
# thread 'main' (2447) panicked at emulator-asm/asm-runner/src/asm_services/services.rs:157:9:
# Timeout: service `mo` not ready on 127.0.0.1:23115
# ```
# With `-u`:
# ```
# thread '<unnamed>' (2529) panicked at /home/runner/work/zisk/zisk/executor/src/executor.rs:372:18:
# Error during ROM Histogram execution: Failed to read full response payload
#
# Caused by:
#     failed to fill whole buffer
# ```
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
# TODO: Doesn't work, expects a tty. Works if you install inside the container
#RUN curl https://raw.githubusercontent.com/0xPolygonHermez/zisk/main/ziskup/install.sh | bash
#ENV PATH="/root/.zisk/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]
