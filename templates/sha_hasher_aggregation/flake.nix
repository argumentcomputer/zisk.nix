{
  description = "Template ZisK Nix flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.follows = "zisk/nixpkgs";
    flake-parts.follows = "zisk/flake-parts";

    zisk = {
      url = "github:argumentcomputer/zisk.nix";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    zisk,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
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
      }: {
        devShells.default = pkgs.mkShell {
          inputsFrom = [zisk.devShells.${system}.default];
          packages = with pkgs; [
            rust-analyzer
          ];
          RUSTFLAGS = builtins.map (a: "-L ${a}/lib") [pkgs.libgit2];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          NIX_CXXSTDLIB_COMPILE = "-include cstdint";
          NIX_CFLAGS_COMPILE = "-D_GNU_SOURCE";
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            zlib
            stdenv.cc.cc.lib
            openssl
            gmp
            libsodium
            postgresql
            mpi
            llvmPackages.openmp
          ]);
        };
      };
    };
}
