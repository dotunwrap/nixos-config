{ nixpkgs-stable, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  stable-pkgs = import nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  cfg = config.programs.sdrpp;

  # Override sdrpp to include custom plugins
  sdrpp-with-plugins = stable-pkgs.sdrpp.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      # Copy custom plugins into the package
      ${lib.concatMapStringsSep "\n" (plugin: ''
        cp ${plugin} $out/lib/sdrpp/plugins/${builtins.baseNameOf plugin}
        chmod +x $out/lib/sdrpp/plugins/${builtins.baseNameOf plugin}
        ${pkgs.patchelf}/bin/patchelf --set-rpath "$out/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}" \
          $out/lib/sdrpp/plugins/${builtins.baseNameOf plugin} || true
      '') cfg.plugins}
    '';
  });
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      (if cfg.plugins != [] then sdrpp-with-plugins else stable-pkgs.sdrpp)
    ];
  };
}
