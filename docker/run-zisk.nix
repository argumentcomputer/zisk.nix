{pkgs, ...}:
pkgs.writeShellScriptBin "zisk-run" ''
  ${pkgs.podman}/bin/podman run -it \
    localhost/cargo-zisk:latest
''
