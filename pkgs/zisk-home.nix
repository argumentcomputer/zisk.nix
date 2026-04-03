{
  lib,
  stdenv,
  pkgs,
  cargo-zisk,
  ziskemu,
  zisk-toolchain,
  ziskSrc,
  craneLib,
  proofmanSrc,
  nasm,
  gmp,
}: let
  common = import ./common.nix {inherit lib stdenv pkgs craneLib ziskSrc proofmanSrc;};

  # Build libziskclib from the zisk Rust workspace, reusing shared deps
  ziskcLib = craneLib.buildPackage (common.commonArgs
    // {
      inherit (common) cargoArtifacts;
      pname = "zisk-libs";

      cargoExtraArgs = "--lib -p ziskclib";

      installPhaseCommand = ''
        mkdir -p $out
        cp target/release/libziskclib.a $out/
      '';
    });
in
  stdenv.mkDerivation {
    name = "zisk-home";

    src = ./.;

    nativeBuildInputs = [nasm];
    buildInputs = [gmp];

    buildPhase = ''
      # Create the expected ~/.zisk directory structure

      # Link binaries to bin/
      mkdir -p "$out/.zisk/bin"
      ln -s ${cargo-zisk}/bin/cargo-zisk $out/.zisk/bin
      ln -s ${cargo-zisk}/bin/riscv2zisk $out/.zisk/bin
      ln -s ${cargo-zisk}/bin/zisk-coordinator $out/.zisk/bin
      ln -s ${cargo-zisk}/bin/zisk-worker $out/.zisk/bin
      ln -s ${ziskemu}/bin/ziskemu $out/.zisk/bin
      ln -s ${ziskcLib}/libziskclib.a $out/.zisk/bin

      # Link Rust toolchain
      mkdir -p $out/.zisk/toolchains
      ln -s ${zisk-toolchain} $out/.zisk/toolchains/${zisk-toolchain.version}
      ls $out/.zisk/toolchains -alh

      # Copy zisk libraries and build libziskc.a
      mkdir -p $out/.zisk/zisk/emulator-asm
      cp -R ${ziskSrc}/emulator-asm/src/ $out/.zisk/zisk/emulator-asm/
      cp -R ${ziskSrc}/emulator-asm/Makefile $out/.zisk/zisk/emulator-asm/

      # Build libziskc.a in a temporary writable directory
      mkdir -p /build/lib-c-build
      cp -R ${ziskSrc}/lib-c/c/* /build/lib-c-build/
      (cd /build/lib-c-build && make)

      # Copy lib-c and make it writable, then add the built library
      cp -R ${ziskSrc}/lib-c $out/.zisk/zisk/
      chmod -R u+w $out/.zisk/zisk/lib-c
      mkdir -p $out/.zisk/zisk/lib-c/c/lib
      cp /build/lib-c-build/lib/libziskc.a $out/.zisk/zisk/lib-c/c/lib/

      ls $out/.zisk/zisk -alh
    '';

    installPhase = ''
      # Already handled in buildPhase
    '';
  }
