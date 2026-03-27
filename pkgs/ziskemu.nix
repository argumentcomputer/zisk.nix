{
  lib,
  stdenv,
  rustPlatform,
  pkgs,
  ziskSrc,
  proofmanSrc,
}: let
  common = import ./common.nix {inherit lib stdenv pkgs proofmanSrc;};
in
  rustPlatform.buildRustPackage rec {
    pname = "ziskemu";
    version = "0.16.1";

    src = ziskSrc;
    cargoHash = "sha256-DTD9NeTfhatR9gCIaZXoIpiXLyY0/hiauSSxsc9FZq8=";

    buildAndTestSubdir = "emulator";

    postPatch = common.pil2StarkPostPatch;

    nativeBuildInputs =
      common.nativeBuildInputs
      ++ [
        pkgs.gcc
      ];

    inherit (common) buildInputs LIBCLANG_PATH LD_LIBRARY_PATH;
  }
