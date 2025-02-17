{ pkgs, ... }:

{
  imports = [
    ./mini.nix
  ];

  programs.nvf.settings.vim = {
    telescope.enable = true;
    autocomplete.blink-cmp.enable = true;
    formatter.conform-nvim.enable = true;
    snippets.luasnip.enable = true;
    notes.todo-comments.enable = true;

    fzf-lua = {
      enable = true;
      profile = "default-title";
    };

    lazy.plugins = {
      "mason.nvim" = {
        package = pkgs.vimPlugins.mason-nvim;
        setupModule = "mason";
      };
      # "vimplugin-mason-null-ls.nvim" = {
      #   package = {
      #     name = "mason-null-ls.nvim";
      #     src = pkgs.vimPlugins.mason-null-ls-nvim;
      #   };
      # };
      # "vimplugin-mason-nvim-dap.nvim" = {
      #   package = {
      #     name = "mason-nvim-dap.nvim";
      #     src = pkgs.vimPlugins.mason-nvim-dap-nvim;
      #   };
      # };
    };
  };
}
