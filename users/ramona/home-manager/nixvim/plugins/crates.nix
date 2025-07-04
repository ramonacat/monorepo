_: {
  config = {
    programs.nixvim.plugins.crates = {
      enable = true;
      settings.completion.cmp.enabled = true;
    };
  };
}
