{
  stdenv,
  cargo-zisk,
  proving-key,
  ziskemu,
  zisk-toolchain,
  fetchgit,
  rustPlatform,
  nasm,
  gmp,
}: let
  ziskSrc = fetchgit {
    url = "https://github.com/0xPolygonHermez/zisk";
    rev = "v0.15.0";
    sha256 = "sha256-hzV4NedLnKV1JN497S7iiUq91NQltyx3M1W33SKWkeE=";
  };
  # Build libziskclib from the zisk Rust workspace
  ziskcLib = rustPlatform.buildRustPackage {
    pname = "zisk-libs";
    version = "0.15.0";
    src = ziskSrc;
    cargoHash = "sha256-eczbphLn7MTLlnQvhGNRVUwQM3u8eyBRv0rKyPneFIc=";

    # Only build the ziskclib library
    buildPhase = ''
      cargo build --release --lib -p ziskclib
    '';

    installPhase = ''
      mkdir -p $out
      cp target/release/libziskclib.a $out
    '';

    doCheck = false;
  };
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
      ln -s ${cargo-zisk}/lib/libzisk_witness.so $out/.zisk/bin
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

      # Install proving key
      ln -s ${proving-key} $out/.zisk/provingKey
    '';

    installPhase = ''
      # Already handled in buildPhase
    '';
  }
