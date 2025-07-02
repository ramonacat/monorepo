_: {
  config = {
    programs.nixvim.plugins.treesitter = {
      enable = true;
      settings = {
        highlights.enable = true;
        indent.enable = true;
      };
    };
  };
}
