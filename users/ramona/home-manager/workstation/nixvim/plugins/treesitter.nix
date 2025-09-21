{pkgs, ...}: {
  config = {
    programs.nixvim.plugins.treesitter = {
      enable = true;
      settings = {
        highlights.enable = true;
        indent.enable = true;
        textobjects.enable = true;
      };
      nixvimInjections = true;
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
    };
  };
}
