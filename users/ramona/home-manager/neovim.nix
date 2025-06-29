{pkgs, ...}: {
  config = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      defaultEditor = true;

      plugins = with pkgs.vimPlugins; [
        auto-save-nvim
        cmp-nvim-lsp
        cmp-vsnip
        kanagawa-nvim
        neo-tree-nvim
        nvim-cmp
        nvim-lspconfig
        nvim-treesitter-context
        nvim-treesitter.withAllGrammars
        pest-vim
        telescope-nvim
        vim-vsnip
      ];
      extraLuaConfig = ":luafile ~/.config/nvim/init.lua";
    };

    home.file."./.config/nvim/" = {
      source = ./neovim;
      recursive = true;
    };
  };
}
