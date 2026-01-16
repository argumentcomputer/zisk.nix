{
  lib,
  stdenv,
  rustPlatform,
  fetchgit,
  pkgs,
  makeWrapper,
  ziskToolchain,
}: let
  proofmanSrc = fetchgit {
    url = "https://github.com/0xPolygonHermez/pil2-proofman";
    rev = "v0.15.0";
    sha256 = "sha256-rmx/j9vFvEMMDA3S8C/pHRaCjBI1/H+D41/FWn93oFI=";
    fetchSubmodules = true;
  };
in
  rustPlatform.buildRustPackage rec {
    pname = "cargo-zisk";
    version = "0.15.0";

    src = fetchgit {
      url = "https://github.com/0xPolygonHermez/zisk";
      rev = "v0.15.0";
      sha256 = "sha256-hzV4NedLnKV1JN497S7iiUq91NQltyx3M1W33SKWkeE=";
      fetchSubmodules = true;
    };
    cargoHash = "sha256-eczbphLn7MTLlnQvhGNRVUwQM3u8eyBRv0rKyPneFIc=";

    # Build only the cargo-zisk binary from the cli workspace member
    buildAndTestSubdir = "cli";

    postPatch = ''
      # Set up pil2-stark in the build directory
      cp -r --no-preserve=mode ${proofmanSrc}/pil2-stark /build/pil2-stark
      mkdir -p /build/pil2-stark/.git
      # Patch C++ files to add missing include
      for f in \
        src/rapidsnark/binfile_utils.hpp \
        src/rapidsnark/thread_utils.hpp \
        src/rapidsnark/binfile_writer.hpp
      do
        sed -i '1i #include <cstdint>' $NIX_BUILD_TOP/pil2-stark/$f
      done

      # Remove rustup-specific +zisk arguments (we'll use RUSTC env var instead)
      sed -i 's/\["+zisk", "build"\]/["build"]/g' cli/src/commands/build.rs
      sed -i 's/\["+zisk", "run"\]/["run"]/g' cli/src/commands/run.rs
      sed -i 's/\["+zisk", "build"\]/["build"]/g' ziskbuild/src/command.rs
    '';

    nativeBuildInputs = with pkgs; [
      pkg-config
      protobuf
      nasm
      clang
      gnumake
      cmake
      gcc
      llvmPackages.openmp
      pkgsCross.riscv64-embedded.buildPackages.gcc
      makeWrapper
    ];

    buildInputs = with pkgs; [
      grpc
      gmp
      jq
      libsodium
      libpqxx
      libuuid
      openssl
      postgresql
      secp256k1
      nlohmann_json
      libgit2
      zlib
      mkl
      mpi
    ];

    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

    LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs;
      [
        zlib
        stdenv.cc.cc.lib
        openssl
        gmp
        libsodium
        postgresql
        llvmPackages.openmp
      ]
      ++ lib.optionals stdenv.isLinux [
        mpi
      ]);

    # Disable tests as they may require network access or specific setup
    doCheck = false;

    # Wrap cargo-zisk to use the zisk rustc and preserve library paths
    postInstall = ''
      wrapProgram $out/bin/cargo-zisk \
        --set RUSTC "${ziskToolchain}/bin/rustc" \
        --prefix LD_LIBRARY_PATH : "${LD_LIBRARY_PATH}"
    '';
  }
