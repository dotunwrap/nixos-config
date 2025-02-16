{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
    cargo-watch
  ];
}
