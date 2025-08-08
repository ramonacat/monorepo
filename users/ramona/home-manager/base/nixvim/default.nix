_: {
  imports = [
    ./plugins

    ./colorscheme.nix
    ./diagnostics.nix
    ./options.nix
  ];
  config = {
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    home.sessionVariables.EDITOR = "vim";
  };
}
