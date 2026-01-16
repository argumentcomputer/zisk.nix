{
  autoPatchelfHook,
  fetchurl,
  gccForLibs,
  stdenv,
  zlib,
}: let
  version = "1.89.0";
in
  stdenv.mkDerivation {
    pname = "zisk-toolchain-bin";
    inherit version;
    src = fetchurl {
      url = "https://github.com/0xPolygonHermez/rust/releases/download/zisk-0.4.0/rust-toolchain-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-Znui2EI/aqz6p83GCtnYuC+JieNxN4+Kb6XVz5rdGwU=";
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
      ls -alh bin
      ls -alh lib
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
