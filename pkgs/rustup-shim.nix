{
  symlinkJoin,
  writeShellApplication,
  zisk-toolchain,
  rustToolchain,
}:
let
  # Shim that dispatches to zisk-toolchain when RUSTUP_TOOLCHAIN=zisk
  rustc-shim = writeShellApplication {
    name = "rustc";
    runtimeInputs = [];
    text = ''
      if [ "''${RUSTUP_TOOLCHAIN:-}" = "zisk" ]; then
        exec ${zisk-toolchain}/bin/rustc "$@"
      fi
      exec ${rustToolchain}/bin/rustc "$@"
    '';
  };
  # Shim that strips +zisk from cargo args (rustup convention not available in Nix)
  cargo-shim = writeShellApplication {
    name = "cargo";
    runtimeInputs = [];
    text = ''
      args=()
      for arg in "$@"; do
        if [ "$arg" = "+zisk" ]; then
          continue
        fi
        args+=("$arg")
      done
      exec ${rustToolchain}/bin/cargo "''${args[@]}"
    '';
  };
in
symlinkJoin {
  name = "rust-toolchain-with-zisk";
  paths = [cargo-shim rustc-shim rustToolchain];
}
