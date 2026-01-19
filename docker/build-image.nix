{pkgs, ...}: let
  dockerfile = ./Dockerfile;
in
pkgs.writeShellScriptBin "zisk-build" ''
  echo "Building Zisk image"
  ${pkgs.podman}/bin/podman build \
    -f ${dockerfile} \
    -t localhost/cargo-zisk:latest \
    "''${1:-$PWD}"
''
