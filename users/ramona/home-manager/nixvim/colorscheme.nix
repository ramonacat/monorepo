_: {
  config = {
    programs.nixvim = {
      colorschemes.kanagawa = {
        enable = true;
        settings.theme = "dragon";
      };

      highlight = {
        Normal.ctermbg = "none";
        NonText.ctermbg = "none";
      };
    };
  };
}
