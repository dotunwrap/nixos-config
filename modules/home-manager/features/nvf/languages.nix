{ pkgs, ... }:

{
  programs.nvf.settings.vim = {
    languages = {
      enableLSP = true;
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;
      enableDAP = true;

      nix = {
        enable = true;
        format = {
          type = "nixfmt";
          package = pkgs.nixfmt-rfc-style;
        };
      };
      markdown = {
        enable = true;
        lsp.enable = true;
        format = {
          enable = false;
          type = "prettierd";
        };
      };
      ts.enable = true;
      rust.enable = true;
      go.enable = true;
      python.enable = true;
      html.enable = true;
      lua.enable = true;
      php.enable = true;
      clang.enable = true;
      sql.enable = true;
      css.enable = true;
      tailwind.enable = true;
      svelte.enable = true;
    };

    lsp = {
      formatOnSave = true;
      trouble.enable = true;
      otter-nvim.enable = true;
    };

    debugger = {
      nvim-dap = {
        enable = true;
        ui.enable = true;
      };
    };

    treesitter = {
      enable = true;
      addDefaultGrammars = true;
      autotagHtml = true;
      grammars = pkgs.vimPlugins.nvim-treesitter.allGrammars;
    };
  };
}
