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
        # Remove rustup-specific +zisk toolchain selectors (we use the RUSTC
        # env var instead)
        sed -i 's/vec!\[format!("+{toolchain_name}"), "build".to_string()\]/vec!["build".to_string()]/' cli/src/commands/user/build.rs
        sed -i 's/vec!\["+zisk".to_string(), "build".to_string()\]/vec!["build".to_string()]/' cli/src/commands/user/run.rs
        sed -i 's/\["+zisk", "build"\]/["build"]/g' ziskbuild/src/command.rs
      '';

      nativeBuildInputs =
        common.commonArgs.nativeBuildInputs
        ++ [
          pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc
          makeWrapper
        ];

      postInstall = ''
        for bin in cargo-zisk cargo-zisk-dev; do
          wrapProgram $out/bin/$bin \
            --set RUSTC "${zisk-toolchain}/bin/rustc" \
            --prefix LD_LIBRARY_PATH : "${common.commonArgs.LD_LIBRARY_PATH}"
        done

        for bin in riscv2zisk zisk-coordinator zisk-worker; do
          if [ -f "$out/bin/$bin" ]; then
            wrapProgram $out/bin/$bin \
              --prefix LD_LIBRARY_PATH : "${common.commonArgs.LD_LIBRARY_PATH}"
          fi
        done
      '';
    })
