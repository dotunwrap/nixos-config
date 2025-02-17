{ ... }:

{
  programs.nvf.settings.vim.languages = {
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
}
