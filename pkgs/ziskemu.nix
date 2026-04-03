{
  lib,
  stdenv,
  pkgs,
  craneLib,
  ziskSrc,
  proofmanSrc,
}: let
  common = import ./common.nix {inherit lib stdenv pkgs craneLib ziskSrc proofmanSrc;};
in
  craneLib.buildPackage (common.commonArgs
    // {
      inherit (common) cargoArtifacts;
      pname = "ziskemu";

      cargoExtraArgs = "-p ziskemu";

      nativeBuildInputs =
        common.commonArgs.nativeBuildInputs
        ++ [
          pkgs.gcc
        ];
    })
