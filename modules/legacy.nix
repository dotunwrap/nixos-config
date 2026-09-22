{
  imports = [
    ../parts/auxillary.nix
    ../parts/home-configs.nix
    ../parts/home-modules.nix
    ../parts/nixos-modules.nix
    ../parts/system-configs.nix

    ../nixos/configurations
    ../home/configurations

    ../home/modules
    ../nixos/modules
  ];
}
