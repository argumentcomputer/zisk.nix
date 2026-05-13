# NOTE: Downloads the upstream proving key (~33GB extracted) and generates the
# constant tree on top via `cargo-zisk check-setup -a`. Rebuilds take 5-10 min.
{
  lib,
  stdenv,
  cargo-zisk,
  fetchurl,
}:
# TODO: Don't hardcode version
# TODO: Potentially download .md5 checksum and compare for safety
stdenv.mkDerivation {
  name = "proving-key";
  src = fetchurl {
    url = "https://storage.googleapis.com/zisk-setup/zisk-provingkey-0.17.0.tar.gz";
    hash = lib.fakeHash;
  };

  buildPhase = ''
    # Generate constant tree
    ${cargo-zisk}/bin/cargo-zisk check-setup -a --proving-key .
  '';
  installPhase = ''
    mkdir -p $out
    mv ./* $out
  '';
}
