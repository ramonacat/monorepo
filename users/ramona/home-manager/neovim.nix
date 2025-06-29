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
        blink-cmp
        friendly-snippets
        kanagawa-nvim
        neo-tree-nvim
        nvim-lspconfig
        nvim-treesitter-context
        nvim-treesitter.withAllGrammars
        pest-vim
        telescope-nvim
      ];
      extraLuaConfig = ":luafile ~/.config/nvim/init.lua";
    };

    home.file."./.config/nvim/" = {
      source = ./neovim;
      recursive = true;
    };
  };
}
