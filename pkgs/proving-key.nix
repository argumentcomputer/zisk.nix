# NOTE: Generates a 33GB proving key, modify this file at your own peril. Rebuilds take 5-10 minutes
{
  stdenv,
  cargo-zisk,
  fetchurl,
}:
# TODO: Don't hardcode version
# TODO: Potentially download .md5 checksum and compare for safety
stdenv.mkDerivation {
  name = "proving-key";
  src = fetchurl {
    url = "https://storage.googleapis.com/zisk-setup/zisk-provingkey-0.16.0.tar.gz";
    hash = "sha256-3Exmssygwh2ZC1y9KZF+jX+KU0w4MKxXC9ZI25ItnrM";
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
