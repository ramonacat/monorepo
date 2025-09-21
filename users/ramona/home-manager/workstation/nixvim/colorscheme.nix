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

      # The highlight option does not accept guibg as a variable for some reason
      extraConfigVim = ''
        highlight Normal guibg=none
        highlight NonText guibg=none
      '';
    };
  };
}
