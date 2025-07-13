_: {
  config = {
    programs.atuin = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        sync_address = "http://hallewell:8888";
        sync_frequency = "10s";
      };
    };
  };
}
