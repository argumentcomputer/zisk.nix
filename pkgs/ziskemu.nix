{
  lib,
  stdenv,
  rustPlatform,
  fetchgit,
  pkgs,
}: let
  proofmanSrc = fetchgit {
    url = "https://github.com/0xPolygonHermez/pil2-proofman";
    rev = "v0.15.0";
    sha256 = "sha256-rmx/j9vFvEMMDA3S8C/pHRaCjBI1/H+D41/FWn93oFI=";
    fetchSubmodules = true;
  };
in
  rustPlatform.buildRustPackage rec {
    pname = "ziskemu";
    version = "0.15.0";

    src = fetchgit {
      url = "https://github.com/0xPolygonHermez/zisk";
      rev = "v0.15.0";
      sha256 = "sha256-hzV4NedLnKV1JN497S7iiUq91NQltyx3M1W33SKWkeE=";
      fetchSubmodules = true;
    };
    cargoHash = "sha256-eczbphLn7MTLlnQvhGNRVUwQM3u8eyBRv0rKyPneFIc=";

    # Build only the ziskemu binary from the emulator workspace member
    buildAndTestSubdir = "emulator";

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
  }
