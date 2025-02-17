{ ... }:

{
  programs.nvf.settings.vim.options = {
    tabstop = 2;
    softtabstop = 2;
    showtabline = 2;
    expandtab = true;

    shiftwidth = 2;
    breakindent = true;

    wrap = false;

    hlsearch = true;
    incsearch = true;

    splitbelow = true;
    splitright = true;

    ignorecase = true;
    smartcase = true;
    grepprg = "rg --vimgrep";
    grepformat = "%f:%l:%c:%m";

    updatetime = 50;

    swapfile = false;
    backup = false;
    undofile = true;

    termguicolors = true;

    signcolumn = "yes";

    cursorline = false;

    foldcolumn = "0";
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;
    foldmethod = "expr";
    foldexpr = "v:lua.vim.treesitter.foldexpr()";

    scrolloff = 8;
    
    colorcolumn  ="80";

    timeoutlen = 1000;

    encoding = "utf-8";
    fileencoding = "utf-8";

    showmode = false;

    pumheight = 0;
  };
}
