_: {
  config = {
    programs.nixvim.plugins.blink-cmp = {
      enable = true;
      settings = {
        keymap = {
          preset = "super-tab";
          "<C-Space>" = false;
          "<C-p>" = ["show"];
          "<CR>" = ["accept" "fallback"];
        };
        sources.providers = {
          crates = {
            enabled = true;
            name = "crates";
            module = "blink.compat.source";
          };
        };
      };
    };
  };
}
