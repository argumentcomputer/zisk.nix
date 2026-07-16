{
  autoPatchelfHook,
  fetchurl,
  gccForLibs,
  stdenv,
  zlib,
}: let
  version = "1.94.0";
in
  stdenv.mkDerivation {
    pname = "zisk-toolchain-bin";
    inherit version;
    src = fetchurl {
      url = "https://github.com/0xPolygonHermez/rust/releases/download/zisk-1.0.0/rust-toolchain-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-KHx+WrqJwV9zbgBWFzDr2PLRfl4wtIHCRLpAPykekfE=";
    };
    nativeBuildInputs = [
      autoPatchelfHook
    ];
    buildInputs = [
      gccForLibs.lib
      zlib
    ];
    dontStrip = true;

    unpackPhase = ''
      runHook preUnpack
      tar -xzf $src
      runHook postUnpack
    '';
    installPhase = ''
      mkdir -p $out
      mv bin lib $out/
    '';

    passthru = {
      inherit version;
    };
  }
