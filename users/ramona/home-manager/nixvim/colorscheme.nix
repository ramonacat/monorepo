_: {
  config = {
    programs.nixvim = {
      colorschemes.kanagawa = {
        enable = true;
        settings.theme = "dragon";
      };

      highlight = {
        Normal.guibg = "none";
        NonText.guibg = "none";
        Normal.ctermbg = "none";
        NonText.ctermbg = "none";
      };
    };
  };
}
