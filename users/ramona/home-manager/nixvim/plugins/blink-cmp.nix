{config, ...}: {
  config = {
    programs.nixvim.plugins.blink-cmp = {
      enable = true;
      settings.keymap = {
        preset = "enter";
        "<C-Space>" = false;
        "<C-p>" = config.lib.nixvim.mkRaw "function(cmp) cmp.show() end";
      };
    };
  };
}
