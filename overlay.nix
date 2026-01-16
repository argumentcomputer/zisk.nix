final: prev: let
  # Create Zisk toolchain
  ziskToolchain = prev.callPackage ./pkgs/zisk-toolchain.nix {};
in rec {
  # Create a Zisk-specific rustPlatform
  ziskPlatform = prev.makeRustPlatform {
    rustc = final.rust-bin.zisk.latest;
    cargo = final.rust-bin.zisk.latest;
  };

  # Export zisk toolchain
  zisk-toolchain = ziskToolchain;

  # Cargo-zisk package
  cargo-zisk = prev.callPackage ./pkgs/cargo-zisk.nix {
    inherit ziskToolchain;
  };

  # Zisk home directory structure
  zisk-home = prev.callPackage ./pkgs/zisk-home.nix {
    inherit cargo-zisk ziskToolchain proving-key;
  };

  ziskemu = prev.callPackage ./pkgs/ziskemu.nix {};

  proving-key = prev.callPackage ./pkgs/proving-key.nix {};
}
