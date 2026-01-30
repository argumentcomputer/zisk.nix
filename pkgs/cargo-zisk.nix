{
  lib,
  stdenv,
  rustPlatform,
  fetchgit,
  pkgs,
  makeWrapper,
  zisk-toolchain,
  # GPU support (requires Nvidia GPU and CUDA toolkit)
  # Enable with: cargo-zisk.override { enableGpu = true; }
  enableGpu ? false,
  cudaPackages ? pkgs.cudaPackages,
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

    # Build binaries from multiple workspace members
    cargoBuildFlags = [
      "--package"
      "cargo-zisk"
      "--package"
      "zisk-core"
      "--package"
      "zisk-distributed-coordinator"
      "--package"
      "zisk-distributed-worker"
    ] ++ lib.optionals enableGpu [
      "--features"
      "gpu"
    ];

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
      llvmPackages.openmp
      pkgsCross.riscv64-embedded.buildPackages.gcc
      makeWrapper
    ] ++ lib.optionals enableGpu [
      cudaPackages.cuda_nvcc
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
    ] ++ lib.optionals enableGpu [
      cudaPackages.cudatoolkit
      cudaPackages.cuda_cudart
    ];

    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

    # CUDA environment variables (only when GPU support is enabled)
    CUDA_PATH = lib.optionalString enableGpu "${cudaPackages.cudatoolkit}";
    CUDA_HOME = lib.optionalString enableGpu "${cudaPackages.cudatoolkit}";

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
      ]
      ++ lib.optionals enableGpu [
        cudaPackages.cuda_cudart
        cudaPackages.cudatoolkit
      ]);

    # Disable tests as they may require network access or specific setup
    doCheck = false;

    # Wrap all binaries to preserve library paths and set RUSTC for cargo-zisk
    postInstall = ''
      wrapProgram $out/bin/cargo-zisk \
        --set RUSTC "${zisk-toolchain}/bin/rustc" \
        --prefix LD_LIBRARY_PATH : "${LD_LIBRARY_PATH}"

      # Wrap distributed binaries (coordinator, worker) and riscv2zisk
      for bin in riscv2zisk zisk-coordinator zisk-worker; do
        if [ -f "$out/bin/$bin" ]; then
          wrapProgram $out/bin/$bin \
            --prefix LD_LIBRARY_PATH : "${LD_LIBRARY_PATH}"
        fi
      done
    '';
  }
