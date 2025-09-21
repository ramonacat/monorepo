_: {
  config = {
    programs.nixvim.plugins.treesitter-context = {
      enable = true;
      settings = {
        max_lines = 1;
      };
    };
  };
}
