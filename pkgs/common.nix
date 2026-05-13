# Shared Crane build configuration for zisk packages
{
  lib,
  stdenv,
  pkgs,
  craneLib,
  ziskSrc,
  proofmanSrc,
}: rec {
  version = "0.17.0";

  # Pre-built pil2-stark with libstarks.a (build.rs sees it exists and skips make)
  pil2Stark = pkgs.callPackage ./pil2-stark.nix {inherit proofmanSrc;};

  cargoVendorDir = craneLib.vendorCargoDeps {
    src = ziskSrc;
    # Patch proofman-starks-lib-c build.rs to accept PIL2_STARK_DIR env var
    # and skip make invocations (the prebuilt pil2Stark already ships libstarks.a).
    # The upstream hardcodes ../../pil2-stark and always runs make, which breaks
    # in vendored builds where the path doesn't exist and the store is read-only.
    overrideVendorGitCheckout = _ps: drv:
      drv.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            for f in $out/proofman-starks-lib-c-*/build.rs; do
              [ -f "$f" ] || continue
              sed -i 's@let pil2_stark_path_raw = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../pil2-stark");@let pil2_stark_path_raw = std::env::var("PIL2_STARK_DIR").map(std::path::PathBuf::from).unwrap_or_else(|_| Path::new(env!("CARGO_MANIFEST_DIR")).join("../../pil2-stark"));@' "$f"
              sed -i 's@run_command("make"@run_command("true"@g' "$f"
            done
          '';
      });
  };

  commonArgs = {
    pname = "zisk";
    inherit version cargoVendorDir;
    src = ziskSrc;
    strictDeps = true;
    doCheck = false;
    PIL2_STARK_DIR = "${pil2Stark}";

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
        libgit2
        postgresql
        llvmPackages.openmp
      ]
      ++ lib.optionals stdenv.isLinux [
        mpi
      ]);
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
}
