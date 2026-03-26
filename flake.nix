{
  description = "Zisk Nix flake";

  # nixConfig = {
  #   extra-substituters = [
  #     "https://cache.garnix.io"
  #   ];
  #   extra-trusted-public-keys = [
  #     "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  #   ];
  # };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Rust-related inputs
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    fenix,
  }:
    flake-parts.lib.mkFlake {inherit inputs;}
    {
      flake.templates = import ./templates;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = {
        system,
        pkgs,
        ...
      }: let
        rustToolchain = fenix.packages.${system}.fromToolchainFile {
          file = ./rust-toolchain.toml;
          sha256 = "sha256-qqF33vNuAdU5vua96VKVIwuc43j4EFeEXbjQ6+l4mO4=";
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) ["mkl"];
        };

        ziskSrc = pkgs.fetchgit {
          url = "https://github.com/0xPolygonHermez/zisk";
          rev = "v0.16.1";
          sha256 = "sha256-4LG9R9CpsP4kLJ6Cvk8Afu7wGYjxTl1ZLIrgFPdTdAM=";
          fetchSubmodules = true;
        };
        ziskSrcLite = pkgs.fetchgit {
          url = "https://github.com/0xPolygonHermez/zisk";
          rev = "v0.16.1";
          sha256 = "sha256-4LG9R9CpsP4kLJ6Cvk8Afu7wGYjxTl1ZLIrgFPdTdAM=";
        };
        proofmanSrc = pkgs.fetchgit {
          url = "https://github.com/0xPolygonHermez/pil2-proofman";
          rev = "v0.16.1";
          sha256 = "sha256-iVBcuUgi8OEPbxQRHHVcSYlhHBcxbHS9F1Rx9Rr73Kg=";
          fetchSubmodules = true;
        };

        zisk-toolchain = pkgs.callPackage ./pkgs/zisk-toolchain.nix {};
        cargo-zisk = pkgs.callPackage ./pkgs/cargo-zisk.nix {
          inherit ziskSrc proofmanSrc zisk-toolchain;
        };
        ziskemu = pkgs.callPackage ./pkgs/ziskemu.nix {
          inherit ziskSrc proofmanSrc;
        };
        proving-key = pkgs.callPackage ./pkgs/proving-key.nix {
          inherit cargo-zisk;
        };
        zisk-home = pkgs.callPackage ./pkgs/zisk-home.nix {
          inherit cargo-zisk zisk-toolchain ziskemu;
          ziskSrc = ziskSrcLite;
        };
        rustup-shim = pkgs.callPackage ./pkgs/rustup-shim.nix {
          inherit zisk-toolchain rustToolchain;
        };
      in {
        packages = {
          inherit cargo-zisk ziskemu zisk-home zisk-toolchain proving-key rustup-shim;
          build-image = pkgs.callPackage ./docker/build-image.nix {};
          run-zisk = pkgs.callPackage ./docker/run-zisk.nix {};
          zisk-shell = pkgs.callPackage ./docker/zisk-shell.nix {};
        };
        devShells.default = let
          riscv-cross = pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc;
          # Symlink riscv64-unknown-elf-* to riscv64-none-elf-* (zisk expects the former)
          riscv-toolchain = pkgs.runCommand "riscv64-unknown-elf-toolchain" {} ''
            mkdir -p $out/bin
            for bin in ${riscv-cross}/bin/riscv64-none-elf-*; do
              ln -s "$bin" "$out/bin/riscv64-unknown-elf-''${bin##*riscv64-none-elf-}"
            done
          '';
        in pkgs.mkShell {
          # ZISK_DIR = "${zisk-home}/.zisk";
          packages =
            [
              # Zisk-specific tools
              cargo-zisk
              ziskemu
              riscv-toolchain
            ]
            ++ [
              rustup-shim
            ]
            ++ (with pkgs; [
              gmp
              libsodium
              grpc
              jq
              libpqxx
              libuuid
              openssl
              postgresql
              protobuf
              secp256k1
              nlohmann_json
              nasm
              libgit2
              mpi
              clang
              zlib
              llvmPackages.openmp
              mkl
            ]);
          RUSTFLAGS = builtins.map (a: "-L ${a}/lib") [pkgs.libgit2];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          # pil2-proofman C++ headers missing <cstdint> include (needed by newer compilers)
          NIX_CXXFLAGS_COMPILE = "-include cstdint";

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            zlib
            stdenv.cc.cc.lib # libstdc++, libgcc_s
            openssl
            gmp
            libsodium
            postgresql
            mpi
            llvmPackages.openmp
            # Add any other libraries the build scripts might need
          ]);

          shellHook = ''
            echo "Standard Rust: $(cargo --version)"

            # Set up ZISK_DIR in $HOME
            export ZISK_DIR="$HOME/.zisk"
            mkdir -p "$ZISK_DIR"

            # Always sync binaries from Nix store to ensure updates are applied
            echo "Syncing ZisK binaries from Nix store..."
            ${pkgs.rsync}/bin/rsync -a --delete ${zisk-home}/.zisk/bin/ "$ZISK_DIR/bin/"

            # Sync toolchains and zisk directory (read-only, executable where needed)
            if [ ! -e "$ZISK_DIR/toolchains" ]; then
              cp -r ${zisk-home}/.zisk/toolchains "$ZISK_DIR/"
            fi
            if [ ! -e "$ZISK_DIR/zisk" ]; then
              cp -r ${zisk-home}/.zisk/zisk "$ZISK_DIR/"
            fi

            # Download proving key from GCS if not already present
            if [ ! -d "$ZISK_DIR/provingKey" ]; then
              echo "Downloading proving key (this may take a while)..."
              rm -rf "$ZISK_DIR/provingKey"
              ZISK_SETUP_FILE="zisk-provingkey-0.16.0.tar.gz"
              if ${pkgs.curl}/bin/curl -fL -o "/tmp/$ZISK_SETUP_FILE" \
                "https://storage.googleapis.com/zisk-setup/$ZISK_SETUP_FILE"; then
                ${pkgs.gnutar}/bin/tar xf "/tmp/$ZISK_SETUP_FILE" -C "$ZISK_DIR"
                rm -f "/tmp/$ZISK_SETUP_FILE"
                echo "Generating constant tree..."
                ${cargo-zisk}/bin/cargo-zisk check-setup -a
                echo "Proving key setup complete."
              else
                echo "WARNING: Failed to download proving key. Proving will not work."
                echo "You can manually download from: https://storage.googleapis.com/zisk-setup/$ZISK_SETUP_FILE"
              fi
            fi

            # Create writable cache directory for runtime-generated files
            mkdir -p "$ZISK_DIR/cache"
          '';
        };
      };
    };
}
