{
  lib,
  stdenv,
  rustPlatform,
  pkgs,
  makeWrapper,
  ziskSrc,
  proofmanSrc,
  zisk-toolchain,
}:
let
  common = import ./common.nix { inherit lib stdenv pkgs proofmanSrc; };
in
  rustPlatform.buildRustPackage rec {
    pname = "cargo-zisk";
    version = "0.16.1";

    src = ziskSrc;
    cargoHash = "sha256-DTD9NeTfhatR9gCIaZXoIpiXLyY0/hiauSSxsc9FZq8=";

    cargoBuildFlags = [
      "--package" "cargo-zisk"
      "--package" "zisk-core"
      "--package" "zisk-distributed-coordinator"
      "--package" "zisk-distributed-worker"
    ];

    postPatch = common.pil2StarkPostPatch + ''
      # Remove rustup-specific +zisk arguments (we'll use RUSTC env var instead)
      sed -i 's/\["+zisk", "build"\]/["build"]/g' cli/src/commands/build.rs
      sed -i 's/\["+zisk", "run"\]/["run"]/g' cli/src/commands/run.rs
      sed -i 's/\["+zisk", "build"\]/["build"]/g' ziskbuild/src/command.rs
    '';

    nativeBuildInputs = common.nativeBuildInputs ++ [
      pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc
      makeWrapper
    ];

    inherit (common) buildInputs LIBCLANG_PATH LD_LIBRARY_PATH;

    doCheck = false;

    postInstall = ''
      wrapProgram $out/bin/cargo-zisk \
        --set RUSTC "${zisk-toolchain}/bin/rustc" \
        --prefix LD_LIBRARY_PATH : "${common.LD_LIBRARY_PATH}"

      for bin in riscv2zisk zisk-coordinator zisk-worker; do
        if [ -f "$out/bin/$bin" ]; then
          wrapProgram $out/bin/$bin \
            --prefix LD_LIBRARY_PATH : "${common.LD_LIBRARY_PATH}"
        fi
      done
    '';
  }
