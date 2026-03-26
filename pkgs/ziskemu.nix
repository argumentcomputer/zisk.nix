{
  lib,
  stdenv,
  rustPlatform,
  pkgs,
  ziskSrc,
  proofmanSrc,
}:
  rustPlatform.buildRustPackage rec {
    pname = "ziskemu";
    version = "0.16.1";

    src = ziskSrc;
    cargoHash = "sha256-DTD9NeTfhatR9gCIaZXoIpiXLyY0/hiauSSxsc9FZq8=";

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
