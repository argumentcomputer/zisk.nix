{
  lib,
  stdenv,
  pkgs,
  makeWrapper,
  craneLib,
  ziskSrc,
  proofmanSrc,
  zisk-toolchain,
}: let
  common = import ./common.nix {inherit lib stdenv pkgs craneLib ziskSrc proofmanSrc;};
in
  craneLib.buildPackage (common.commonArgs
    // {
      inherit (common) cargoArtifacts;
      pname = "cargo-zisk";

      cargoExtraArgs = "-p cargo-zisk -p zisk-core -p zisk-coordinator-server -p zisk-worker";

      postPatch = ''
        # Remove rustup-specific +zisk arguments (we use RUSTC env var instead)
        sed -i 's/\["+zisk", "build"\]/["build"]/g' cli/src/commands/build.rs
        sed -i 's/\["+zisk", "run"\]/["run"]/g' cli/src/commands/run.rs
        sed -i 's/\["+zisk", "build"\]/["build"]/g' ziskbuild/src/command.rs
      '';

      nativeBuildInputs =
        common.commonArgs.nativeBuildInputs
        ++ [
          pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc
          makeWrapper
        ];

      postInstall = ''
        wrapProgram $out/bin/cargo-zisk \
          --set RUSTC "${zisk-toolchain}/bin/rustc" \
          --prefix LD_LIBRARY_PATH : "${common.commonArgs.LD_LIBRARY_PATH}"

        for bin in riscv2zisk zisk-coordinator zisk-worker; do
          if [ -f "$out/bin/$bin" ]; then
            wrapProgram $out/bin/$bin \
              --prefix LD_LIBRARY_PATH : "${common.commonArgs.LD_LIBRARY_PATH}"
          fi
        done
      '';
    })
