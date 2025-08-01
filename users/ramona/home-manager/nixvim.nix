_: {
  imports = import ../../../libs/nix/nix-files-from-dir.nix ./nixvim;
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
