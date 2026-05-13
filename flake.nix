{
  description = "Zisk Nix flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Rust-related inputs
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    fenix,
    crane,
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
          sha256 = "sha256-zC8E38iDVJ1oPIzCqTk/Ujo9+9kx9dXq7wAwPMpkpg0=";
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) ["mkl"];
        };

        ziskSrc = pkgs.fetchgit {
          url = "https://github.com/0xPolygonHermez/zisk";
          rev = "v0.17.0";
          sha256 = "sha256-ZVlMF3EUzk1kajzXwnW7+Tj1Ms9p6bFGGZPKx7v1nZo=";
          fetchSubmodules = true;
        };
        ziskSrcLite = pkgs.fetchgit {
          url = "https://github.com/0xPolygonHermez/zisk";
          rev = "v0.17.0";
          sha256 = "sha256-ZVlMF3EUzk1kajzXwnW7+Tj1Ms9p6bFGGZPKx7v1nZo=";
        };
        proofmanSrc = pkgs.fetchgit {
          url = "https://github.com/0xPolygonHermez/pil2-proofman";
          rev = "v0.17.0";
          sha256 = "sha256-JmFlGh+q82v/p8Eg0YO6GvwQyyS/dQW0udPGizo2H+g=";
          fetchSubmodules = true;
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        zisk-toolchain = pkgs.callPackage ./pkgs/zisk-toolchain.nix {};
        cargo-zisk = pkgs.callPackage ./pkgs/cargo-zisk.nix {
          inherit craneLib ziskSrc proofmanSrc zisk-toolchain;
        };
        ziskemu = pkgs.callPackage ./pkgs/ziskemu.nix {
          inherit craneLib ziskSrc proofmanSrc;
        };
        proving-key = pkgs.callPackage ./pkgs/proving-key.nix {
          inherit cargo-zisk;
        };
        install-proving-key = pkgs.writeShellApplication {
          name = "install-proving-key";
          runtimeInputs = [pkgs.curl pkgs.gnutar cargo-zisk];
          text = ''
            ZISK_DIR="''${ZISK_DIR:-$HOME/.zisk}"
            mkdir -p "$ZISK_DIR"
            ZISK_SETUP_FILE="zisk-provingkey-0.17.0.tar.gz"
            echo "Downloading proving key to $ZISK_DIR (this may take a while)..."
            rm -rf "$ZISK_DIR/provingKey"
            curl -fL -o "/tmp/$ZISK_SETUP_FILE" \
              "https://storage.googleapis.com/zisk-setup/$ZISK_SETUP_FILE"
            tar xf "/tmp/$ZISK_SETUP_FILE" -C "$ZISK_DIR"
            rm -f "/tmp/$ZISK_SETUP_FILE"
            echo "Generating constant tree..."
            cargo-zisk check-setup -a
            echo "Proving key setup complete."
          '';
        };
        zisk-home = pkgs.callPackage ./pkgs/zisk-home.nix {
          inherit cargo-zisk zisk-toolchain ziskemu craneLib proofmanSrc;
          ziskSrc = ziskSrcLite;
        };
        rustup-shim = pkgs.callPackage ./pkgs/rustup-shim.nix {
          inherit zisk-toolchain rustToolchain;
        };
      in {
        packages = {
          inherit cargo-zisk ziskemu zisk-home zisk-toolchain proving-key install-proving-key rustup-shim;
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
        in
          pkgs.mkShell {
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
            # NIX_CXXSTDLIB_COMPILE is only injected for C++ (g++), not C or assembly
            NIX_CXXSTDLIB_COMPILE = "-include cstdint";
            # _GNU_SOURCE needed for memfd_create in libffi-sys; safe for C, C++, and assembly
            NIX_CFLAGS_COMPILE = "-D_GNU_SOURCE";

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
              # -rlptD instead of -a: skip owner/group preservation since we're syncing
              # nix-store files into $HOME, where the nixbld group isn't valid.
              ${pkgs.rsync}/bin/rsync -rlptD --delete ${zisk-home}/.zisk/bin/ "$ZISK_DIR/bin/"

              # Sync toolchains and zisk directory (read-only, executable where needed)
              if [ ! -e "$ZISK_DIR/toolchains" ]; then
                cp -r ${zisk-home}/.zisk/toolchains "$ZISK_DIR/"
              fi
              if [ ! -e "$ZISK_DIR/zisk" ]; then
                cp -r ${zisk-home}/.zisk/zisk "$ZISK_DIR/"
              fi

              if [ ! -d "$ZISK_DIR/provingKey" ]; then
                echo "Proving key not found at $ZISK_DIR/provingKey."
                echo "Run 'nix run .#install-proving-key' to download it (required for proving)."
              fi

              # Create writable cache directory for runtime-generated files
              mkdir -p "$ZISK_DIR/cache"
            '';
          };
      };
    };
}
