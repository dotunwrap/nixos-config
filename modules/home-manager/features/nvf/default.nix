{ inputs, ... }:

{
  imports = [inputs.nvf.homeManagerModules.default];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        languages = {
          enableLSP = true;
          enableTreesitter = true;

          nix.enable = true;
          ts.enable = true;
          rust.enable = true;
          go.enable = true;
          python.enable = true;
          html.enable = true;
          lua.enable = true;
          php.enable = true;
          clang.enable = true;
          markdown.enable = true;
          sql.enable = true;
        };
      };
    };
  };
}
