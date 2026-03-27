# Shared build configuration for zisk packages that depend on pil2-proofman
{
  lib,
  stdenv,
  pkgs,
  proofmanSrc,
}: rec {
  # pil2-proofman's build.rs expects pil2-stark at CARGO_MANIFEST_DIR/../../pil2-stark.
  # In Nix vendored builds the manifest lives under /build/<pname>-<version>-vendor/source-git-0/,
  # so we copy pil2-stark into the vendor root and patch the missing <cstdint> include.
  pil2StarkPostPatch = ''
    pil2dir="/build/$pname-$version-vendor/pil2-stark"
    cp -r --no-preserve=mode ${proofmanSrc}/pil2-stark "$pil2dir"
    mkdir -p "$pil2dir/.git"
    for f in \
      src/rapidsnark/binfile_utils.hpp \
      src/rapidsnark/thread_utils.hpp \
      src/rapidsnark/binfile_writer.hpp
    do
      sed -i '1i #include <cstdint>' "$pil2dir/$f"
    done
  '';

  nativeBuildInputs = with pkgs; [
    pkg-config
    protobuf
    nasm
    clang
    gnumake
    cmake
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
}
