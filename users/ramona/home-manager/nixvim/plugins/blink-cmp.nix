_: {
  config = {
    programs.nixvim.plugins.blink-cmp = {
      enable = true;
      settings.keymap = {
        preset = "super-tab";
        "<C-Space>" = false;
        "<C-p>" = ["show"];
        "<CR>" = ["accept" "fallback"];
      };
    };
  };
}
