_: {
  config = {
    programs.nixvim.plugins.auto-save = {
      enable = true;
      settings = {
        write_all_buffers = true;
      };
    };
  };
}
