{
  description = "A very basic flake";

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
          sha256 = "sha256-sqSWJDUxc+zaz1nBWMAJKTAGBuGWP25GCftIOlCEAtA=";
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "mkl"
              # CUDA packages for GPU support
              "cuda_cudart"
              "cuda_nvcc"
              "cuda_cccl"
              "libcublas"
              "libcufft"
              "libnpp"
              "cudatoolkit"
            ];
        };

        zisk-toolchain = pkgs.callPackage ./pkgs/zisk-toolchain.nix {};
        cargo-zisk = pkgs.callPackage ./pkgs/cargo-zisk.nix {
          inherit zisk-toolchain;
        };
        ziskemu = pkgs.callPackage ./pkgs/ziskemu.nix {};
        proving-key = pkgs.callPackage ./pkgs/proving-key.nix {
          inherit cargo-zisk;
        };
        zisk-home = pkgs.callPackage ./pkgs/zisk-home.nix {
          inherit cargo-zisk zisk-toolchain ziskemu proving-key;
        };
      in {
        packages = {
          inherit cargo-zisk ziskemu zisk-home zisk-toolchain proving-key;
          build-image = pkgs.callPackage ./docker/build-image.nix {};
          run-zisk = pkgs.callPackage ./docker/run-zisk.nix {};
          zisk-shell = pkgs.callPackage ./docker/zisk-shell.nix {};
        };
        devShells.default = pkgs.mkShell {
          ZISK_DIR = "${zisk-home}/.zisk";
          packages =
            [
              # Zisk-specific tools
              cargo-zisk
              ziskemu
            ]
            ++ (with pkgs; [
              rustToolchain
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

            # Symlink large provingKey instead of copying
            [ ! -e "$ZISK_DIR/provingKey" ] && ln -sf ${zisk-home}/.zisk/provingKey "$ZISK_DIR/provingKey"

            # Create writable cache directory for runtime-generated files
            mkdir -p "$ZISK_DIR/cache"
          '';
        };
      };
    };
}
