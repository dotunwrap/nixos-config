{
  firefoxAddonPackages,
  pkgs,
  ...
}:
{
  policies = import ./policies.nix;
  profiles.default = {
    settings = import ./settings.nix;
    extensions.packages = import ./extensions.nix firefoxAddonPackages;
    search = import ./search-engines.nix pkgs;
    keyboardShortcuts = import ./shortcuts.nix;
    keyboardShortcutsVersion = 21;
  };
}
