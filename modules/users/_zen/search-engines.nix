pkgs: {
  force = true;
  default = "ddg";
  privateDefault = "ddg";
  engines = {
    mynixos = {
      name = "MyNixOS";
      urls = [
        {
          template = "https://mynixos.com/search?q={searchTerms}";
          params = [
            {
              name = "query";
              value = "searchTerms";
            }
          ];
        }
      ];
      icons = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@nx" ];
    };
  };
}
