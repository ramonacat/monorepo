_: {
  config = {
    programs.nixvim.plugins.blink-cmp = {
      enable = true;
      settings.keymap = {
        preset = "enter";
        "<C-Space>" = false;
        "<C-p>" = ["show"];
      };
    };
  };
}
