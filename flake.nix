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
      # Follow lean4-nix nixpkgs so we stay in sync
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

      flake = {
        overlays.default = import ./overlay.nix;
      };

      perSystem = {
        system,
        pkgs,
        ...
      }: let
        rustToolchain = fenix.packages.${system}.fromToolchainFile {
          file = ./rust-toolchain.toml;
          sha256 = "sha256-sqSWJDUxc+zaz1nBWMAJKTAGBuGWP25GCftIOlCEAtA=";
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) ["mkl"];
          overlays = [self.overlays.default];
        };
        packages = {
          inherit (pkgs) cargo-zisk ziskemu zisk-home zisk-toolchain proving-key;
          #default = pkgs.cargo-zisk;
          build-image = pkgs.writeShellScriptBin "zisk-build" ''
            echo "Building Zisk image"
            ${pkgs.podman}/bin/podman build \
              -t localhost/cargo-zisk:latest \
              "''${1:-$PWD}"
          '';
          run-zisk = pkgs.writeShellScriptBin "zisk-run" ''
            ${pkgs.podman}/bin/podman run -it --rm \
            localhost/cargo-zisk:latest
          '';
        };
        devShells.default = pkgs.mkShell {
          ZISK_DIR = "${pkgs.zisk-home}/.zisk";
          packages = with pkgs; [
            # Zisk-specific toolchain and tools
            cargo-zisk
            ziskemu
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
          ];
          RUSTFLAGS = builtins.map (a: "-L ${a}/lib") [pkgs.libgit2];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            zlib
            stdenv.cc.cc.lib # libstdc++, libgcc_s
            openssl
            gmp
            libsodium
            postgresql
            openmpi
            llvmPackages.openmp
            # Add any other libraries the build scripts might need
          ]);

          shellHook = ''
            echo "Standard Rust: $(cargo --version)"

            # Set up writable ZISK_DIR in $HOME
            export ZISK_DIR="$HOME/.zisk"
            mkdir -p "$ZISK_DIR"

            # Copy static files from Nix store if not present (except large provingKey)
            if [ ! -e "$ZISK_DIR/bin" ]; then
              cp -r ${pkgs.zisk-home}/.zisk/bin "$ZISK_DIR/"
              chmod -R u+w "$ZISK_DIR/bin"
            fi
            if [ ! -e "$ZISK_DIR/toolchains" ]; then
              cp -r ${pkgs.zisk-home}/.zisk/toolchains "$ZISK_DIR/"
              chmod -R u+w "$ZISK_DIR/toolchains"
            fi
            if [ ! -e "$ZISK_DIR/zisk" ]; then
              cp -r ${pkgs.zisk-home}/.zisk/zisk "$ZISK_DIR/"
              chmod -R u+w "$ZISK_DIR/zisk"
            fi

            # Symlink large provingKey instead of copying
            [ ! -e "$ZISK_DIR/provingKey" ] && ln -s ${pkgs.zisk-home}/.zisk/provingKey "$ZISK_DIR/provingKey"

            # Create cache directory for runtime-generated files
            mkdir -p "$ZISK_DIR/cache"

            # Create compatibility symlinks for libraries with version mismatches
            COMPAT_LIB_DIR="/tmp/zisk-compat-libs-$$"
            mkdir -p "$COMPAT_LIB_DIR"
            ln -sf ${pkgs.libsodium}/lib/libsodium.so.26 "$COMPAT_LIB_DIR/libsodium.so.23"
            ln -sf ${pkgs.llvmPackages.openmp}/lib/libomp.so "$COMPAT_LIB_DIR/libomp.so.5"
            export LD_LIBRARY_PATH="$COMPAT_LIB_DIR:$LD_LIBRARY_PATH"
          '';
        };
      };
    };
}
